import UIKit

protocol CreateReadingListDelegate: NSObjectProtocol {
    func createReadingList(_ createReadingList: CreateReadingListViewController, shouldCreateReadingList: Bool, with name: String, description: String?, articles: [WMFArticle])
}

class CreateReadingListViewController: UIViewController, UITextFieldDelegate {
        
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var readingListNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var readingListNameTextField: ThemeableTextField!
    @IBOutlet weak var descriptionTextField: ThemeableTextField!
    
    @IBOutlet weak var createReadingListButton: WMFAuthButton!
    
    fileprivate var theme: Theme = Theme.standard
    fileprivate let articles: [WMFArticle]
    public let moveFromReadingList: ReadingList?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
        readingListNameTextField.delegate = self
        descriptionTextField.delegate = self
        readingListNameTextField.returnKeyType = .next
        readingListNameTextField.enablesReturnKeyAutomatically = true
        
        readingListNameTextField.placeholder = "reading list title"
        descriptionTextField.placeholder = "optional short description"
        
        createReadingListButton.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(false)
    }
    
    @objc func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    init(theme: Theme, articles: [WMFArticle], moveFromReadingList: ReadingList? = nil) {
        self.theme = theme
        self.articles = articles
        self.moveFromReadingList = moveFromReadingList
        super.init(nibName: "CreateReadingListViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var delegate: CreateReadingListDelegate?
    
    @IBAction func createReadingListButtonPressed() {
        guard let name = readingListNameTextField.text, !name.isEmpty else {
            return
        }
        delegate?.createReadingList(self, shouldCreateReadingList: true, with: name, description: descriptionTextField.text, articles: articles)
    }
    
    // MARK: - UITextFieldDelegate
    
    fileprivate var isReadingListFieldEmpty: Bool {
        return readingListNameTextField.text?.isEmpty ?? true
    }
    
    fileprivate var isDescriptionFieldEmpty: Bool {
        return descriptionTextField.text?.isEmpty ?? true
    }
    
    @IBAction func textFieldDidChange(_ textField: UITextField) {
        createReadingListButton.isEnabled = !isReadingListFieldEmpty
        showDoneReturnKeyIfNecessary()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        readingListNameTextField.becomeFirstResponder()
    }
    
    func showDoneReturnKeyIfNecessary() {
        if !isReadingListFieldEmpty && !isDescriptionFieldEmpty {
            descriptionTextField.returnKeyType = .done
        } else {
            descriptionTextField.returnKeyType = .default
        }
        if descriptionTextField.isFirstResponder {
            descriptionTextField.resignFirstResponder()
            descriptionTextField.becomeFirstResponder()
        } else {
            readingListNameTextField.resignFirstResponder()
            readingListNameTextField.becomeFirstResponder()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard !descriptionTextField.isFirstResponder else {
            createReadingListButtonPressed()
            return true
        }
        if readingListNameTextField.isFirstResponder {
            descriptionTextField.becomeFirstResponder()
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        createReadingListButton.isEnabled = false
        showDoneReturnKeyIfNecessary()
        return true
    }
}

extension CreateReadingListViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        view.tintColor = theme.colors.link
        
        readingListNameTextField.apply(theme: theme)
        descriptionTextField.apply(theme: theme)
        
        titleLabel.textColor = theme.colors.primaryText
        readingListNameLabel.textColor = theme.colors.secondaryText
        descriptionLabel.textColor = theme.colors.secondaryText
        
        createReadingListButton.apply(theme: theme)
       
    }
}
