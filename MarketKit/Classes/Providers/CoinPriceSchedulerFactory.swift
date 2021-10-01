import Foundation
import HsToolKit

class CoinPriceSchedulerFactory {
    private let manager: CoinPriceManager
    private let coinManager: CoinManager
    private let reachabilityManager: IReachabilityManager
    private var logger: Logger?

    init(manager: CoinPriceManager, coinManager: CoinManager, reachabilityManager: IReachabilityManager, logger: Logger? = nil) {
        self.manager = manager
        self.coinManager = coinManager
        self.reachabilityManager = reachabilityManager
        self.logger = logger
    }

    func scheduler(currencyCode: String, coinUidDataSource: ICoinPriceCoinUidDataSource) -> Scheduler {
        let schedulerProvider = CoinPriceSchedulerProvider(
                manager: manager,
                coinManager: coinManager,
                currencyCode: currencyCode
        )

        schedulerProvider.dataSource = coinUidDataSource

        return Scheduler(provider: schedulerProvider, reachabilityManager: reachabilityManager, logger: logger)
    }

}
