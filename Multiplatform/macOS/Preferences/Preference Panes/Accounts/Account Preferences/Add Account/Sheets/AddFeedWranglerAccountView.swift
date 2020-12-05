//
//  AddFeedWranglerAccountView.swift
//  Multiplatform macOS
//
//  Created by Stuart Breckenridge on 03/12/2020.
//  Copyright © 2020 Ranchero Software. All rights reserved.
//

import SwiftUI
import Account
import RSCore
import RSWeb
import Secrets

fileprivate class AddFeedWrangerViewModel: ObservableObject {
	@Published var isAuthenticating: Bool = false
	@Published var accountUpdateError: AccountUpdateErrors = .none
	@Published var showError: Bool = false
	@Published var username: String = ""
	@Published var password: String = ""
}

struct AddFeedWranglerAccountView: View {
    
	@Environment (\.presentationMode) var presentationMode
	@StateObject private var model = AddFeedWrangerViewModel()
	
	var body: some View {
		VStack {
			HStack(spacing: 16) {
				VStack(alignment: .leading) {
					AccountType.feedWrangler.image()
						.resizable()
						.frame(width: 50, height: 50)
					Spacer()
				}
				VStack(alignment: .leading, spacing: 8) {
					Text("Sign in to your Feed Wrangler account.")
						.font(.headline)
					HStack {
						Text("Don't have a Feed Wrangler account?")
							.font(.callout)
						Button(action: {
							NSWorkspace.shared.open(URL(string: "https://feedwrangler.net/users/new")!)
						}, label: {
							Text("Sign up here.").font(.callout)
						}).buttonStyle(LinkButtonStyle())
					}
					
					HStack {
						VStack(alignment: .trailing, spacing: 14) {
							Text("Email")
							Text("Password")
						}
						VStack(spacing: 8) {
							TextField("me@email.com", text: $model.username)
							SecureField("•••••••••••", text: $model.password)
						}
					}
					
					Text("Your username and password will be encrypted and stored in Keychain.")
						.foregroundColor(.secondary)
						.font(.callout)
						.lineLimit(2)
						.padding(.top, 4)
					
					Spacer()
					HStack(spacing: 8) {
						Spacer()
						ProgressView()
							.scaleEffect(CGSize(width: 0.5, height: 0.5))
							.hidden(!model.isAuthenticating)
						Button(action: {
							presentationMode.wrappedValue.dismiss()
						}, label: {
							Text("Cancel")
								.frame(width: 60)
						}).keyboardShortcut(.cancelAction)

						Button(action: {
							authenticateFeedWrangler()
						}, label: {
							Text("Create")
								.frame(width: 60)
						})
						.keyboardShortcut(.defaultAction)
						.disabled(model.username.isEmpty || model.password.isEmpty)
					}
				}
			}
		}
		.padding()
		.frame(width: 400, height: 220)
		.textFieldStyle(RoundedBorderTextFieldStyle())
    }
	
	
	private func authenticateFeedWrangler() {
		
		model.isAuthenticating = true
		let credentials = Credentials(type: .feedWranglerBasic, username: model.username, secret: model.password)
		
		Account.validateCredentials(type: .feedWrangler, credentials: credentials) { result in
			
			
			self.model.isAuthenticating = false
			
			switch result {
			case .success(let validatedCredentials):
				
				guard let validatedCredentials = validatedCredentials else {
					self.model.accountUpdateError = .invalidUsernamePassword
					self.model.showError = true
					return
				}
				
				let account = AccountManager.shared.createAccount(type: .feedWrangler)
				
				do {
					try account.removeCredentials(type: .feedWranglerBasic)
					try account.removeCredentials(type: .feedWranglerToken)
					try account.storeCredentials(credentials)
					try account.storeCredentials(validatedCredentials)
					account.refreshAll(completion: { result in
						switch result {
						case .success:
							self.presentationMode.wrappedValue.dismiss()
						case .failure(let error):
							self.model.accountUpdateError = .other(error: error)
							self.model.showError = true
						}
					})
					
				} catch {
					self.model.accountUpdateError = .keyChainError
					self.model.showError = true
				}
				
			case .failure:
				self.model.accountUpdateError = .networkError
				self.model.showError = true
			}
		}
	}
}

struct AddFeedWranglerAccountView_Previews: PreviewProvider {
    static var previews: some View {
        AddFeedWranglerAccountView()
    }
}
