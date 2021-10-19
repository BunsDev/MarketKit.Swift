import RxSwift
import RxRelay

class CoinManager {
    private let storage: CoinStorage
    private let hsProvider: HsProvider
    private let hsOldProvider: HsOldProvider
    private let coinGeckoProvider: CoinGeckoProvider
    private let defiYieldProvider: DefiYieldProvider
    private let categoryManager: CoinCategoryManager
    private let exchangeManager: ExchangeManager

    private let fullCoinsUpdatedRelay = PublishRelay<Void>()

    init(storage: CoinStorage, hsProvider: HsProvider, hsOldProvider: HsOldProvider, coinGeckoProvider: CoinGeckoProvider, defiYieldProvider: DefiYieldProvider,
         categoryManager: CoinCategoryManager, exchangeManager: ExchangeManager) {
        self.storage = storage
        self.hsProvider = hsProvider
        self.hsOldProvider = hsOldProvider
        self.coinGeckoProvider = coinGeckoProvider
        self.defiYieldProvider = defiYieldProvider
        self.categoryManager = categoryManager
        self.exchangeManager = exchangeManager
    }

    func marketInfos(rawMarketInfos: [MarketInfoRaw]) -> [MarketInfo] {
        do {
            let fullCoins = try storage.fullCoins(coinUids: rawMarketInfos.map { $0.uid })
            let dictionary = fullCoins.reduce(into: [String: FullCoin]()) { $0[$1.coin.uid] = $1 }

            return rawMarketInfos.compactMap { rawMarketInfo in
                guard let fullCoin = dictionary[rawMarketInfo.uid] else {
                    return nil
                }

                return rawMarketInfo.marketInfo(fullCoin: fullCoin)
            }
        } catch {
            return []
        }
    }

}

extension CoinManager {

    // Coins

    var fullCoinsUpdatedObservable: Observable<Void> {
        fullCoinsUpdatedRelay.asObservable()
    }

    func fullCoins(filter: String, limit: Int) throws -> [FullCoin] {
        try storage.fullCoins(filter: filter, limit: limit)
    }

    func fullCoins(coinUids: [String]) throws -> [FullCoin] {
        try storage.fullCoins(coinUids: coinUids)
    }

    func fullCoins(coinTypes: [CoinType]) throws -> [FullCoin] {
        try storage.fullCoins(coinTypes: coinTypes)
    }

    func platformCoin(coinType: CoinType) throws -> PlatformCoin? {
        try storage.platformCoin(coinType: coinType)
    }

    func platformCoins() throws -> [PlatformCoin] {
        try storage.platformCoins()
    }

    func platformCoins(coinTypes: [CoinType]) throws -> [PlatformCoin] {
        try storage.platformCoins(coinTypeIds: coinTypes.map { $0.id} )
    }

    func platformCoins(coinTypeIds: [String]) throws -> [PlatformCoin] {
        try storage.platformCoins(coinTypeIds: coinTypeIds)
    }

    func coins(filter: String, limit: Int) throws -> [Coin] {
        try storage.coins(filter: filter, limit: limit)
    }

    func handleFetched(fullCoins: [FullCoin]) {
        do {
            try storage.save(fullCoins: fullCoins)
            fullCoinsUpdatedRelay.accept(())
        } catch {
            // todo
        }
    }

    // Market Info

    func marketInfosSingle(top: Int) -> Single<[MarketInfo]> {
        hsProvider.marketInfosSingle(top: top)
                .map { [weak self] rawMarketInfos -> [MarketInfo] in
                    self?.marketInfos(rawMarketInfos: rawMarketInfos) ?? []
                }
    }

    func advancedMarketInfosSingle(top: Int) -> Single<[MarketInfo]> {
        hsProvider.advancedMarketInfosSingle(top: top)
                .map { [weak self] rawMarketInfos -> [MarketInfo] in
                    self?.marketInfos(rawMarketInfos: rawMarketInfos) ?? []
                }
    }

    func marketInfosSingle(coinUids: [String]) -> Single<[MarketInfo]> {
        hsProvider.marketInfosSingle(coinUids: coinUids)
                .map { [weak self] rawMarketInfos -> [MarketInfo] in
                    self?.marketInfos(rawMarketInfos: rawMarketInfos) ?? []
                }
    }

    func marketInfosSingle(categoryUid: String) -> Single<[MarketInfo]> {
        hsProvider.marketInfosSingle(categoryUid: categoryUid)
                .map { [weak self] rawMarketInfos -> [MarketInfo] in
                    self?.marketInfos(rawMarketInfos: rawMarketInfos) ?? []
                }
    }

    func marketInfoOverviewSingle(coinUid: String, currencyCode: String, languageCode: String) -> Single<MarketInfoOverview> {
        hsProvider.marketInfoOverviewSingle(coinUid: coinUid, currencyCode: currencyCode, languageCode: languageCode)
                .map { [weak self] (rawMarketInfoOverview: MarketInfoOverviewRaw) -> MarketInfoOverview in
                    rawMarketInfoOverview.marketInfoOverview(categories: self?.categoryManager.coinCategories(uids: rawMarketInfoOverview.categoryUids) ?? [])
                }
    }

    func marketTickerSingle(coinUid: String) -> Single<[MarketTicker]> {
        guard let coin = try? storage.coin(uid: coinUid),
              let coinGeckoId = coin.coinGeckoId else {
            return Single.just([])
        }

        return coinGeckoProvider.marketTickersSingle(coinId: coinGeckoId)
                .map { [weak self] response in
                    response.marketTickers(imageUrls: self?.exchangeManager.imageUrlsMap(ids: response.exchangeIds) ?? [:])
                }
    }

    func marketInfoDetailsSingle(coinUid: String, currencyCode: String) -> Single<MarketInfoDetails> {
        hsProvider.marketInfoDetailsSingle(coinUid: coinUid, currencyCode: currencyCode)
    }

    func topTokenHoldersSingle(coinUid: String, itemsCount: Int) -> Single<[TokenHolder]> {
        guard let fullCoin = try? storage.fullCoins(coinUids: [coinUid]).first else {
            return Single.just([])
        }

        return hsOldProvider.topTokenHoldersSingle(fullCoin: fullCoin, itemsCount: itemsCount)
    }

    func auditReportsSingle(coinUid: String) -> Single<[Auditor]> {
        guard let fullCoin = try? storage.fullCoins(coinUids: [coinUid]).first else {
            return Single.just([])
        }

        return defiYieldProvider.auditReportsSingle(fullCoin: fullCoin)
    }

}
