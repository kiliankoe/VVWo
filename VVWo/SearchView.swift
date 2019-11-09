import SwiftUI

enum ViewState {
    case ready
    case listening
    case searching
    case failure

    mutating func next() {
        switch self {
        case .ready:
            self = .listening
        case .listening:
            self = .searching
        case .searching:
            self = .ready
        case .failure:
            self = .ready
        }
    }
}

struct SearchView: View {
    @State private var isRunning = true

    @State private var pulsate = false
    @State private var showWaves = false

    @ObservedObject var speechRecognizer = SpeechRecognizer.shared

    @EnvironmentObject var apiClient: API

    @State var viewState = ViewState.ready

    var showResultsView: Binding<Bool> {
        return Binding<Bool>(
            get: { self.apiClient.latestQuery != nil },
            set: { _ in })
    }

    var microphoneButton: some View {
        switch viewState {
        case .ready:
            return AnyView(
                ZStack {
                    Circle()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                    Image(systemName: "mic.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
            )
        case .listening:
            return AnyView(
                ZStack {
                    // Ring
                    Circle()
                        .stroke(lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .scaleEffect(showWaves ? 2 : 1)
                        .hueRotation(.degrees(showWaves ? 360 : 0))
                        .opacity(showWaves ? 0 : 1)
                        .animation(Animation.easeOut(duration: 2).repeatForever(autoreverses: false))
                        .onAppear { self.showWaves.toggle() }

                    Circle()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.green)
                        .scaleEffect(pulsate ? 1 : 1.2)
                        .animation(Animation.easeInOut(duration: 1).repeatForever())
                        .onAppear { self.pulsate.toggle() }

                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
                .onAppear {
                    self.speechRecognizer.startListening()

                }
                .onDisappear {
                    self.speechRecognizer.stopListening()
                    self.showWaves = false
                    self.pulsate = false
                }
            )
        case .searching:
            return AnyView(
                ZStack {
                    Circle()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                    ActivityIndicator()
                }
                .onAppear { self.apiClient.parse(query: self.speechRecognizer.recognizedText ?? "") }
                .onDisappear { self.speechRecognizer.reset() }
            )
        case .failure:
            return AnyView(
                ZStack {
                    Circle()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.red)
                    Image(systemName: "xmark")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
            )
        }
    }

    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [.white, .gray]), center: .center, startRadius: 2, endRadius: 1000)
                .edgesIgnoringSafeArea(.all)
            Image("background")
                .resizable()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)

            VStack {
                Spacer()
                Text(speechRecognizer.recognizedText ?? "")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .frame(height: 200)
                    .padding(.horizontal)
                Spacer()
                microphoneButton
                    .onTapGesture {
                        self.viewState.next()
                    }
                Spacer()
                if viewState == .listening {
                    Button(action: {
                        self.viewState = .ready
                        self.speechRecognizer.reset()
                    }, label: { Text("Abbrechen") })
                } else {
                    Text("") // This is stupid and just for alignment purposes.
                }
                Spacer()
            }
        }
        .shadow(radius: 25)
        .sheet(isPresented: self.showResultsView, content: {
            ResultsList()
                .environmentObject(self.apiClient)
                .onAppear { self.viewState.next() }
                .onDisappear {
                    self.apiClient.latestQuery = nil
                    self.apiClient.resetDVBResponses()
                }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
            .environmentObject(API())
    }
}
