import MarketKit

class Singleton {
    static let instance = Singleton()

    let kit: Kit

    init() {
        kit = try! Kit.instance(hsApiBaseUrl: "https://markets-dev.horizontalsystems.xyz", minLogLevel: .debug)

        kit.sync()
    }

}
