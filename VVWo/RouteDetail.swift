import SwiftUI
import DVB

struct RouteDetail: View {
    var route: Route

    var body: some View {
        VStack {
            RouteMapView(route: route)
                .frame(height: 300)
            List(route.partialRoutes) { partial in
                HStack {
                    if partial.mode.mode?.rawValue != nil {
                        Image(partial.mode.mode!.rawValue)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .cornerRadius(3)
                    }
                    VStack(alignment: .leading) {
                        Text("\(partial.mode.name ?? "") \(partial.mode.direction ?? "")")
                            .font(.headline)
                        Text("\(partial.duration ?? 0) Minuten")
                            .font(Font.subheadline.smallCaps())
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationBarTitle("", displayMode: .inline)
    }
}

//struct RouteDetail_Previews: PreviewProvider {
//    static var previews: some View {
//        RouteDetail()
//    }
//}
