import UIKit
import SnapKit
import RxSwift
import MarketKit

class MarketSearchController: UIViewController {
    private let searchController = UISearchController(searchResultsController: nil)
    private let tableView = UITableView()

    private var currentFilter: String = ""

    private var fullCoins = [FullCoin]()
    private let disposeBag = DisposeBag()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Search"

        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.showsCancelButton = false
        searchController.searchResultsUpdater = self

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.register(MarketSearchCell.self, forCellReuseIdentifier: String(describing: MarketSearchCell.self))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag

        Singleton.instance.kit.fullCoinsUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.syncCoins()
                })
                .disposed(by: disposeBag)

        syncCoins()
    }

    private func syncCoins() {
        do {
            fullCoins = try Singleton.instance.kit.fullCoins(filter: currentFilter)
            tableView.reloadData()
        } catch {
            print("Failed to sync coins: \(error)")
        }
    }

}

extension MarketSearchController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fullCoins.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: String(describing: MarketSearchCell.self), for: indexPath)
    }

}

extension MarketSearchController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? MarketSearchCell {
            cell.bind(fullCoin: fullCoins[indexPath.row])
        }
    }

}

extension MarketSearchController: UISearchResultsUpdating {

    public func updateSearchResults(for searchController: UISearchController) {
        var filter = searchController.searchBar.text?.trimmingCharacters(in: .whitespaces) ?? ""

        if filter != currentFilter {
            currentFilter = filter
            syncCoins()
        }
    }

}
