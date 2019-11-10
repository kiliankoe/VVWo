import Foundation
import Combine
import DVB

class API: ObservableObject {
    var baseURL: URL

    init(url: URL = URL(string: "https://vvwo.kilian.io/")!) {
        self.baseURL = url
    }

    var objectWillChange = ObservableObjectPublisher()

    var latestQuery: QueryResponse? {
        didSet {
            self.objectWillChange.send()
        }
    }

    func parse(query: String) {
        var request = URLRequest(url: self.baseURL.appendingPathComponent("query"))
        request.httpMethod = "POST"

        let escapedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "query=\(escapedQuery)".data(using: .utf8)

        _ = URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: QueryResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                    self.latestQuery = nil
                }
            }) { response in
                print(response)
                self.latestQuery = response
            }
    }

    // This is really icky :/
    var monitorResponse: MonitorResponse?
    var routesResponse: RoutesResponse?

    func resetDVBResponses() {
        self.monitorResponse = nil
        self.routesResponse = nil
    }

    func getDVBData() {
        resetDVBResponses()
        let demoDefaultLoc = "Sächsische Staats- und Unibibliothek"

        guard let latestQuery = latestQuery else { return }
        switch latestQuery.intent.intentName {
        case .departure:
            var location = latestQuery.slots.first { $0.slotName == "location" }?.value.value ?? demoDefaultLoc
            if location == "hier" {
                location = demoDefaultLoc
            }

            var allowedModes = Mode.allRequest
            if let vehicleFilter = latestQuery.slots.first(where: { $0.slotName == "vehicle_type" })?.value.value {
                if ["tram", "bahn", "straßenbahn"].contains(vehicleFilter.lowercased()) {
                    allowedModes = [.tram]
                } else if vehicleFilter.lowercased() == "bus" {
                    allowedModes = [.cityBus, .intercityBus, .plusBus]
                }
            }

            Departure.monitor(stopWithName: location, allowedModes: allowedModes) { result in
                guard let response = try? result.get() else { return }
                DispatchQueue.main.async {
                    self.monitorResponse = response
                    self.objectWillChange.send()
                }
            }
        case .route:
            resetDVBResponses()
            var origin = latestQuery.slots.first { $0.slotName == "location_origin" }?.value.value ?? demoDefaultLoc
            if origin == "hier" {
                origin = demoDefaultLoc
            }
            var destination = latestQuery.slots.first { $0.slotName == "location_destination" }?.value.value ?? demoDefaultLoc
            if destination == "hause" {
                destination = "Albertplatz"
            }

            Route.find(from: origin, to: destination) { result in
                guard let response = try? result.get() else { return }
                DispatchQueue.main.async {
                    self.routesResponse = response
                    self.objectWillChange.send()
                }
            }
        default:
            break
        }
    }
}

struct QueryResponse: Decodable {
    let input: String
    let intent: Intent
    let slots: [Slot]
}

struct Intent: Decodable {
    let intentName: IntentType
    let probability: Double
}

enum IntentType: String, Decodable {
    case search = "kiliankoe:Search"
    case departure = "kiliankoe:Departure"
    case route = "kiliankoe:Route"
    case reachability = "kiliankoe:Reachability"
    case notification = "kiliankoe:Notification"
    case disruption = "kiliankoe:Disruption"
}

struct Slot: Decodable {
    let entity: String
    let range: SlotRange
    let rawValue: String
    let slotName: String
    let value: SlotValue
}

struct SlotRange: Decodable {
    let start: Int
    let end: Int
}

struct SlotValue: Decodable {
    let kind: String
    let value: String
}


extension Departure: Identifiable {
    public var id: String {
        return "\(line) \(direction) \(String(describing: realTime))"
    }
}

extension Route: Identifiable {
    public var id: Int {
        routeId
    }
}

extension Route.RoutePartial: Identifiable {
    public var id: Int {
        partialRouteId ?? -1
    }
}
