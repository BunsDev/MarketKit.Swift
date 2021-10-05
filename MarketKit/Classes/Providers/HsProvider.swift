import Foundation
import RxSwift
import HsToolKit
import Alamofire
import ObjectMapper

class HsProvider {
    private let baseUrl: String
    private let networkManager: NetworkManager

    init(baseUrl: String, networkManager: NetworkManager) {
        self.baseUrl = baseUrl
        self.networkManager = networkManager
    }

}

extension HsProvider {

    func fullCoinsSingle() -> Single<[FullCoinResponse]> {
        networkManager.single(url: "\(baseUrl)/v1/coins", method: .get)
    }

    func marketInfosSingle(top: Int, limit: Int?, order: MarketInfo.Order?) -> Single<[MarketInfoResponse]> {
        var parameters: Parameters = [
            "top": top
        ]

        if let limit = limit {
            parameters["limit"] = limit
        }

        if let order = order {
            parameters["orderField"] = order.field.rawValue
            parameters["orderDirection"] = order.direction.rawValue
        }

        return networkManager.single(url: "\(baseUrl)/v1/coins/top_markets", method: .get, parameters: parameters)
    }

    func marketInfosSingle(coinUids: [String], order: MarketInfo.Order?) -> Single<[MarketInfoResponse]> {
        var parameters: Parameters = [
            "uids": coinUids.joined(separator: ",")
        ]

        if let order = order {
            parameters["orderField"] = order.field.rawValue
            parameters["orderDirection"] = order.direction.rawValue
        }

        return networkManager.single(url: "\(baseUrl)/v1/coins/markets", method: .get, parameters: parameters)
    }

    func marketInfoOverviewSingle(coinUid: String, currencyCode: String, languageCode: String) -> Single<MarketInfoOverviewResponse> {
        networkManager.single(url: "\(baseUrl)/v1/coins/\(coinUid)?currency=\(currencyCode)&language=\(languageCode)", method: .get)
    }

    func coinCategoriesSingle() -> Single<[CoinCategory]> {
        networkManager.single(url: "\(baseUrl)/v1/categories", method: .get)
    }

    func coinPricesSingle(coinUids: [String], currencyCode: String) -> Single<[String: CoinPriceResponse]> {
        let parameters: Parameters = [
            "ids": coinUids.joined(separator: ","),
            "currency": currencyCode
        ]

        return networkManager.single(url: "\(baseUrl)/v1/coins/prices", method: .get, parameters: parameters)
    }

}
