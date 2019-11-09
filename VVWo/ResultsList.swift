import SwiftUI
import DVB

struct ResultsList: View {

    @EnvironmentObject var apiClient: API

    var resultsList: some View {
        if let query = apiClient.latestQuery {
            switch query.intent.intentName {
            case .departure:
                return AnyView(
                    List(apiClient.monitorResponse?.departures ?? []) { departure in
                        DepartureCell(departure: departure)
                    }
                    .navigationBarTitle(apiClient.monitorResponse?.stopName ?? "")
                )
            case .route:
                return AnyView(
                    List(apiClient.routesResponse?.routes ?? []) { route in
                        RouteCell(route: route)
                    }
                    .navigationBarTitle("Verbindung")
                )
            default:
                return AnyView(
                    VStack {
                        Text("Sorry, diese Art Abfrage ist in dieser Demo noch nicht möglich.")
                            .font(.title)
                            .padding(.bottom)
                        Text(String(describing: query))
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.horizontal)
                )
            }
        } else {
            return AnyView(
                Text("🧐")
            )
        }
    }

    var body: some View {
        NavigationView {
            resultsList
        }
        .onAppear { self.apiClient.getDVBData() }
    }
}

struct DepartureCell: View {
    var departure: Departure

    var body: some View {
        HStack {
            Image(departure.mode.rawValue)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .cornerRadius(4)
            VStack(alignment: .leading) {
                Text("\(departure.line) \(departure.direction)")
                    .font(.headline)
                HStack {
                    Text(departure.localizedETA(for: Locale(identifier: "de_DE")))
                        .font(Font.body.smallCaps())
                        .foregroundColor(departure.state == .onTime ? .gray : .red)
                    Spacer()
                    Text(departure.localizedPlatform)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

            }
        }
    }
}

struct RouteCell: View {
    var route: Route

    var firstNonFootpathMode: Route.ModeElement? {
        route.modeChain.first(where: { $0.mode != Mode.unknown("footpath") })
    }

    var body: some View {
        NavigationLink(destination: RouteDetail(route: route)) {
            HStack {
                if firstNonFootpathMode?.mode?.rawValue != nil {
                    Image(firstNonFootpathMode!.mode!.rawValue)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .cornerRadius(3)
                }
                VStack(alignment: .leading) {
                    Text("\(firstNonFootpathMode?.name ?? "") \(firstNonFootpathMode?.direction ?? "")")
                        .font(.headline)
                    if route.price != nil {
                        Text("\(route.price ?? "")€")
                    }
                    HStack {
                        Text("\(route.duration) Minuten")
                        Text(route.interchanges == 1 ? "Kein Umstieg" : "\(route.interchanges) Umstiege")
                    }
                    .font(Font.subheadline.smallCaps())
                }
            }
        }
    }
}

extension Departure {
    var localizedPlatform: String {
        guard let platform = platform else { return "" }
        switch platform.type {
        case "Platform":
            return "Steig \(platform.name)"
        case "Railtrack":
            return "Gleis \(platform.name.replacingOccurrences(of: "Gl.", with: ""))"
        default:
            return "\(platform.type) \(platform.name)"
        }
    }
}

struct ResultsList_Previews: PreviewProvider {
    static var previews: some View {
        ResultsList()
    }
}
