//
//  ActiveWalletViewController.swift
//  BitSense
//
//  Created by Peter on 15/06/20.
//  Copyright © 2020 Fontaine. All rights reserved.
//

import UIKit

class ActiveWalletViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var walletTable: UITableView!
    let ud = UserDefaults.standard
    var existingWallet = ""
    var walletDisabled = Bool()
    var hotBalance = ""
    var coldBalance = ""
    var unconfirmedBalance = ""
    var hotFiat = ""
    var coldFiat = ""
    var uncomfirmedFiat = ""
    var sectionZeroLoaded = Bool()
    var wallets = NSArray()
    var transactionArray = [[String:Any]]()
    var tx = String()
    let spinner = UIActivityIndicatorView(style: .medium)
    var refreshButton = UIBarButtonItem()
    var dataRefresher = UIBarButtonItem()
    var id:UUID!
    var walletLabel:String!
    var wallet:Wallet?
    var window: UIWindow?
    @IBOutlet weak var sendView: UIView!
    @IBOutlet weak var invoiceView: UIView!
    @IBOutlet weak var importView: UIView!
    @IBOutlet weak var utxosView: UIView!
    @IBOutlet weak var advancedView: UIView!
    @IBOutlet weak var fxRateLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        walletTable.delegate = self
        walletTable.dataSource = self
        sendView.layer.cornerRadius = 5
        invoiceView.layer.cornerRadius = 5
        importView.layer.cornerRadius = 5
        utxosView.layer.cornerRadius = 5
        advancedView.layer.cornerRadius = 5
        fxRateLabel.text = ""
        existingWallet = ud.object(forKey: "walletName") as? String ?? ""
        sectionZeroLoaded = false
        NotificationCenter.default.addObserver(self, selector: #selector(refreshWallet), name: .refreshWallet, object: nil)
        addNavBarSpinner()
        loadTable()
    }
    
    @IBAction func getDetails(_ sender: Any) {
        if wallet != nil {
            id = wallet!.id
            walletLabel = wallet!.label
            goToDetail()
        } else {
            showAlert(vc: self, title: "Ooops", message: "That button only works for \"Fully Noded Wallets\" which can be created by tapping the plus button, you can see your Fully Noded Wallets by tapping the squares button. Fully Noded allows you to access, use and create wallets with ultimate flexibility using your node but it comes with some limitations. In order to get a better user experience we recommend creating a Fully Noded Wallet.")
        }
    }
    
    @IBAction func exportWalletAction(_ sender: Any) {
        if wallet != nil {
            DispatchQueue.main.async { [unowned vc = self] in
                vc.performSegue(withIdentifier: "segueToAccountMap", sender: vc)
            }
        } else {
            showAlert(vc: self, title: "Exporting only works for Fully Noded Wallets", message: "You can create a Fully Noded Wallet by tapping the plus button. Fully Noded allows you to access all your nodes wallets, if you created the wallet externally from the app then the app does not have the information it needs to export the wallet.")
        }
    }
    
    
    @IBAction func goToFullyNodedWallets(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToWallets", sender: vc)
        }
    }
    
    @IBAction func createWallet(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "createFullyNodedWallet", sender: vc)
        }
    }
    
    @IBAction func sendAction(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "spendFromWallet", sender: vc)
        }
    }
    
    @IBAction func invoiceAction(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToInvoice", sender: vc)
        }
    }
    
    @IBAction func importAction(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToImport", sender: vc)
        }
    }
    
    @IBAction func invoiceSettings(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "goToInvoiceSetting", sender: vc)
        }
    }
    
    @IBAction func goToUtxos(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToUtxos", sender: vc)
        }
    }
    
    private func loadTable() {
        activeWallet { [unowned vc = self] (wallet) in
            if wallet != nil {
                vc.wallet = wallet!
                vc.existingWallet = wallet!.name
                vc.walletLabel = wallet!.label
                vc.id = wallet!.id
                DispatchQueue.main.async {
                    vc.transactionArray.removeAll()
                    vc.walletTable.reloadData()
                }
            } else {
                vc.walletLabel = nil
            }
            vc.loadBalances()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if transactionArray.count > 0 {
            return 1 + transactionArray.count
        } else {
            return 2
        }
    }
    
    private func balancesCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = walletTable.dequeueReusableCell(withIdentifier: "BalancesCell", for: indexPath)
        let hotBalanceLabel = cell.viewWithTag(1) as! UILabel
        let coldBalanceLabel = cell.viewWithTag(2) as! UILabel
        let unconfirmedLabel = cell.viewWithTag(3) as! UILabel
        let hotFiatLabel = cell.viewWithTag(4) as! UILabel
        let coldFiatLabel = cell.viewWithTag(5) as! UILabel
        let unconfirmedFiatLabel = cell.viewWithTag(6) as! UILabel
        cell.layer.borderColor = UIColor.lightGray.cgColor
        cell.layer.borderWidth = 0.5
        if hotBalance == "" {
            hotBalance = "0.00000000"
        }
        if coldBalance == "" {
            coldBalance = "0.00000000"
        }
        hotFiatLabel.text = hotFiat
        coldFiatLabel.text = coldFiat
        unconfirmedFiatLabel.text = uncomfirmedFiat
        hotBalanceLabel.text = hotBalance
        coldBalanceLabel.text = coldBalance
        unconfirmedLabel.text = unconfirmedBalance
        hotBalanceLabel.adjustsFontSizeToFitWidth = true
        coldBalanceLabel.adjustsFontSizeToFitWidth = true
        unconfirmedLabel.adjustsFontSizeToFitWidth = true
        return cell
    }
    
    private func transactionsCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = walletTable.dequeueReusableCell(withIdentifier: "TransactionCell",
                                                 for: indexPath)
        
        cell.selectionStyle = .none
        
        cell.layer.borderColor = UIColor.lightGray.cgColor
        cell.layer.borderWidth = 0.5
        
        let categoryImage = cell.viewWithTag(1) as! UIImageView
        let amountLabel = cell.viewWithTag(2) as! UILabel
        let confirmationsLabel = cell.viewWithTag(3) as! UILabel
        let labelLabel = cell.viewWithTag(4) as! UILabel
        let dateLabel = cell.viewWithTag(5) as! UILabel
        let watchOnlyLabel = cell.viewWithTag(6) as! UILabel
        
        amountLabel.alpha = 1
        confirmationsLabel.alpha = 1
        labelLabel.alpha = 1
        dateLabel.alpha = 1
        watchOnlyLabel.alpha = 1
        
        let dict = self.transactionArray[indexPath.section - 1]
                        
        confirmationsLabel.text = (dict["confirmations"] as! String) + " " + "confs"
        let label = dict["label"] as? String
        
        if label != "," {
            
            labelLabel.text = label
            
        } else if label == "," {
            
            labelLabel.text = ""
            
        }
        
        dateLabel.text = dict["date"] as? String
        
        if dict["abandoned"] as? Bool == true {
            
            cell.backgroundColor = UIColor.red
            
        }
        
        if dict["involvesWatchonly"] as? Bool == true {
            
            watchOnlyLabel.text = "COLD"
            
        } else {
            
            watchOnlyLabel.text = ""
            
        }
        
        let amount = dict["amount"] as! String
        
        if amount.hasPrefix("-") {
            
            categoryImage.image = UIImage(systemName: "arrow.up.right")
            categoryImage.tintColor = .systemRed
            amountLabel.text = amount
            amountLabel.textColor = UIColor.darkGray
            labelLabel.textColor = UIColor.darkGray
            confirmationsLabel.textColor = UIColor.darkGray
            dateLabel.textColor = UIColor.darkGray
            
        } else {
            
            categoryImage.image = UIImage(systemName: "arrow.down.left")
            categoryImage.tintColor = .systemGreen
            amountLabel.text = "+" + amount
            amountLabel.textColor = .lightGray
            labelLabel.textColor = .lightGray
            confirmationsLabel.textColor = .lightGray
            dateLabel.textColor = .lightGray
            
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if sectionZeroLoaded {
                return balancesCell(indexPath)
            } else {
                return blankCell()
            }
        default:
            if transactionArray.count > 0 {
                return transactionsCell(indexPath)
            } else {
                return blankCell()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.clear
        header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 50)
        let textLabel = UILabel()
        textLabel.textAlignment = .left
        textLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        textLabel.textColor = .white
        textLabel.frame = CGRect(x: 0, y: 0, width: 400, height: 50)
        switch section {
        case 0:
            if walletLabel != nil {
                textLabel.text = walletLabel
            } else {
                textLabel.text = UserDefaults.standard.object(forKey: "walletName") as? String ?? "Default Wallet"
            }
            
        case 1:
            textLabel.text = "Transactions"
            
        default:
            break
        }
        header.addSubview(textLabel)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 || section == 1 {
            return 50
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            if sectionZeroLoaded {
                return 116
            } else {
                return 47
            }
        default:
            if sectionZeroLoaded {
                return 62
            } else {
                return 47
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if transactionArray.count > 0 {
            if indexPath.section > 0 {
                let selectedTx = self.transactionArray[indexPath.section - 1]
                tx = selectedTx["txID"] as! String
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.performSegue(withIdentifier: "getTransaction", sender: vc)
                }
            }
        }
    }
    
    private func blankCell() -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.backgroundColor = #colorLiteral(red: 0.05172085258, green: 0.05855310153, blue: 0.06978280196, alpha: 1)
        return cell
    }
    
    @objc func refreshWallet() {
        existingWallet = ""
        activeWallet { [unowned vc = self] (wallet) in
            if wallet != nil {
                vc.wallet = wallet!
                vc.id = wallet!.id
                vc.walletLabel = wallet!.label
            } else {
                vc.walletLabel = nil
            }
            DispatchQueue.main.async { [unowned vc = self] in
                vc.addNavBarSpinner()
                NodeLogic.walletDisabled = false
                vc.sectionZeroLoaded = false
                vc.transactionArray.removeAll()
                vc.walletTable.reloadData()
                vc.reloadWalletData()
            }
        }
    }
    
    private func checkIfWalletsChanged() {
        let walletName = ud.object(forKey: "walletName") as? String ?? ""
        if walletName != existingWallet {
            existingWallet = walletName
            reloadWalletData()
        }
    }
    
    private func loadBalances() {
        NodeLogic.walletDisabled = walletDisabled
        NodeLogic.loadBalances { [unowned vc = self] (response, errorMessage) in
            if errorMessage != nil {
                if errorMessage!.contains("Wallet file not specified (must request wallet RPC through") {
                    vc.removeSpinner()
                    vc.existingWallet = "multiple wallets"
                    vc.promptToChooseWallet()
                } else {
                    vc.removeSpinner()
                    displayAlert(viewController: vc, isError: true, message: errorMessage!)
                }
            } else if response != nil {
                let str = Balances(dictionary: response!)
                vc.hotBalance = str.hotBalance
                vc.coldBalance = str.coldBalance
                vc.unconfirmedBalance = str.unconfirmedBalance
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.sectionZeroLoaded = true
                    vc.walletTable.reloadSections(IndexSet.init(arrayLiteral: 0), with: .fade)
                    vc.loadSectionOne()
                }
            }
        }
    }
    
    func loadSectionOne() {
        NodeLogic.walletDisabled = walletDisabled
        NodeLogic.loadSectionTwo { [unowned vc = self] (response, errorMessage) in
            if errorMessage != nil {
                vc.removeSpinner()
                displayAlert(viewController: vc, isError: true, message: errorMessage!)
            } else if response != nil {
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.transactionArray.removeAll()
                    vc.transactionArray = response!.reversed()
                    vc.walletTable.reloadData()
                }
                vc.getFiatBalances()
            }
        }
    }
    
    private func getFiatBalances() {
        let fx = FiatConverter.sharedInstance
        fx.getFxRate { [unowned vc = self] rate in
            if rate != nil {
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.fxRateLabel.text = "$\(String(describing: rate!)) / btc"
                }
                if let btcHotBalance = Double(vc.hotBalance) {
                    let hotBalanceFiat = btcHotBalance * rate!
                    vc.hotFiat = "$\(round(hotBalanceFiat).withCommas())"
                }
                if let btcColdBalance = Double(vc.coldBalance) {
                    let coldBalanceFiat = btcColdBalance * rate!
                    vc.coldFiat = "$\(round(coldBalanceFiat).withCommas())"
                }
                if let btcUncomfirmedBalance = Double(vc.unconfirmedBalance) {
                    let unconfirmedBalanceFiat = btcUncomfirmedBalance * rate!
                    vc.uncomfirmedFiat = "$\(round(unconfirmedBalanceFiat).withCommas())"
                }
            } else {
                vc.hotFiat = ""
                vc.coldFiat = ""
                vc.uncomfirmedFiat = ""
            }
            DispatchQueue.main.async { [unowned vc = self] in
                vc.walletTable.reloadSections(IndexSet(arrayLiteral: 0), with: .none)
                vc.removeSpinner()
            }
        }
    }
    
    private func promptToChooseWallet() {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Your node has multiple wallets that are currently loaded, you need to choose which one you want to work with.", message: "", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Choose", style: .default, handler: { [unowned vc = self] action in
                vc.goChooseWallet()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func goChooseWallet() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToChooseWallet", sender: vc)
        }
    }
    
    func reloadWalletData() {
        NodeLogic.loadBalances { [unowned
            vc = self] (response, errorMessage) in
            if errorMessage != nil {
                vc.removeSpinner()
                displayAlert(viewController: vc, isError: true, message: errorMessage!)
            } else if response != nil {
                let str = Balances(dictionary: response!)
                vc.hotBalance = str.hotBalance
                vc.coldBalance = (str.coldBalance)
                vc.unconfirmedBalance = (str.unconfirmedBalance)
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.sectionZeroLoaded = true
                    vc.walletTable.reloadSections(IndexSet.init(arrayLiteral: 0), with: .none)
                }
                NodeLogic.loadSectionTwo { [unowned vc = self] (response, errorMessage) in
                    if errorMessage != nil {
                        vc.removeSpinner()
                        displayAlert(viewController: vc, isError: true, message: errorMessage!)
                    } else if response != nil {
                        DispatchQueue.main.async { [unowned vc = self] in
                            vc.transactionArray.removeAll()
                            vc.transactionArray = response!.reversed()
                            vc.walletTable.reloadData()
                            vc.removeSpinner()
                            vc.getFiatBalances()
                        }
                    }
                }
            }
        }
    }
    
    private func addNavBarSpinner() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.spinner.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            vc.dataRefresher = UIBarButtonItem(customView: vc.spinner)
            vc.navigationItem.setRightBarButton(vc.dataRefresher, animated: true)
            vc.spinner.startAnimating()
            vc.spinner.alpha = 1
        }
    }
    
    private func removeSpinner() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.spinner.stopAnimating()
            vc.spinner.alpha = 0
            vc.refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: vc, action: #selector(vc.refreshData(_:)))
            vc.refreshButton.tintColor = UIColor.lightGray.withAlphaComponent(1)
            vc.navigationItem.setRightBarButton(vc.refreshButton, animated: true)
        }
    }
    
    @objc func refreshData(_ sender: Any) {
        existingWallet = ""
        addNavBarSpinner()
        loadTable()
    }
    
    private func goToDetail() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "segueToActiveWalletDetail", sender: vc)
        }
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
            
        case "segueToActiveWalletDetail":
            
            if let vc = segue.destination as? WalletDetailViewController {
                vc.walletId = id
            }
            
        case "getTransaction":
            
            if let vc = segue.destination as? TransactionViewController {
                vc.txid = tx
            }
            
        case "chooseAWallet":
            
            if let vc = segue.destination as? ChooseWalletViewController {
                vc.wallets = wallets
                vc.doneBlock = { result in
                    self.loadTable()
                }
            }
            
        case "segueToAccountMap":
            if let vc = segue.destination as? QRDisplayerViewController {
                if let json = AccountMap.create(wallet: wallet!) {
                    vc.text = json
                }
            }
            
        case "createFullyNodedWallet":
            if let vc = segue.destination as? CreateFullyNodedWalletViewController {
                vc.onDoneBlock = { success in
                    if success {
                        showAlert(vc: self, title: "Success ✅", message: "Wallet imported successfully, it is now rescanning the blockchain you can monitor rescan status from \"tools\" > \"get wallet info\", historic transactions will not display until the rescan completes.")
                        self.loadTable()
                    }
                }
            }
                    
        default:
            
            break
            
        }
        
    }

}
