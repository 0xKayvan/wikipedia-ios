import UIKit

class InsertMediaCustomImageSizeSettingTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var textFieldLabel: UILabel!
    @IBOutlet weak var textField: ThemeableTextField!

    private var theme = Theme.standard

    func configure(title: String, textFieldLabelText: String, textFieldText: String, theme: Theme) {
        titleLabel.text = title
        textFieldLabel.text = textFieldLabelText
        textField.text = textFieldText
        apply(theme: theme)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        textFieldLabel.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        textField.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
    }

    override var isUserInteractionEnabled: Bool {
        didSet {
            textField.isUserInteractionEnabled = isUserInteractionEnabled
            apply(theme: theme)
        }
    }
}

extension InsertMediaCustomImageSizeSettingTableViewCell: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        let textColor = isUserInteractionEnabled ? theme.colors.primaryText : theme.colors.secondaryText
        titleLabel.textColor = textColor
        textFieldLabel.textColor = textColor
        textField.textColor = textColor
    }
}
