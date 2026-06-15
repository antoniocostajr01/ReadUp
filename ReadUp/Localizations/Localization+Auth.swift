//
//  Localization+Auth.swift
//  ReadUp
//

import Foundation

public extension Localization {
    enum Auth: LocalizationProtocol {
        case loginTitle
        case email
        case password
        case forgotPassword
        case signIn
        case createAccount
        case name
        case lastName
        case confirmPassword
        case passwordsMismatch
        case acceptTerms
        case termsTitle
        case termsBody
        case terms
        case forgotPasswordTitle
        case forgotPasswordDescription
        case sendCode
        case resetPasswordTitle
        case resetPasswordDescription
        case spamHint
        case codePlaceholder
        case newPassword
        case confirmNewPassword
        case resetPasswordButton
        case passwordUpdated
        case backToLogin
        case passwordResetSuccess
        case appleCredentialsError

        public var key: String.LocalizationValue {
            switch self {
            case .loginTitle: "auth.login.title"
            case .email: "auth.email"
            case .password: "auth.password"
            case .forgotPassword: "auth.forgotPassword"
            case .signIn: "auth.signIn"
            case .createAccount: "auth.createAccount"
            case .name: "auth.name"
            case .lastName: "auth.lastName"
            case .confirmPassword: "auth.confirmPassword"
            case .passwordsMismatch: "auth.passwordsMismatch"
            case .acceptTerms: "auth.acceptTerms"
            case .termsTitle: "auth.termsTitle"
            case .termsBody: "auth.termsBody"
            case .terms: "auth.terms"
            case .forgotPasswordTitle: "auth.forgotPassword.title"
            case .forgotPasswordDescription: "auth.forgotPassword.description"
            case .sendCode: "auth.sendCode"
            case .resetPasswordTitle: "auth.resetPassword.title"
            case .resetPasswordDescription: "auth.resetPassword.description"
            case .spamHint: "auth.resetPassword.spamHint"
            case .codePlaceholder: "auth.resetPassword.codePlaceholder"
            case .newPassword: "auth.newPassword"
            case .confirmNewPassword: "auth.confirmNewPassword"
            case .resetPasswordButton: "auth.resetPassword.button"
            case .passwordUpdated: "auth.passwordUpdated"
            case .backToLogin: "auth.backToLogin"
            case .passwordResetSuccess: "auth.passwordResetSuccess"
            case .appleCredentialsError: "auth.appleCredentialsError"
            }
        }
    }
}
