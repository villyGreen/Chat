//
//  UsersViewModel.swift
//  ChatFirestoreExample
//
//  Created by Alisa Mylnikova on 12.06.2023.
//

import Foundation
import FirebaseFirestore

class UsersViewModel: ObservableObject {

    @Published var searchableText: String = ""

    // group creation
    @Published var selectedUsers: [User] = []
    @Published var picture: Media?
    @Published var title: String = ""

    var filteredUsers: [User] {
        if searchableText.isEmpty {
            return users
        }
        return users.filter {
            $0.name.lowercased().contains(searchableText.lowercased())
        }
    }

    @Published private var users: [User] // not including current user
    @Published private var conversations: [Conversation]

    init(users: [User], conversations: [Conversation]) {
        self.users = users
        self.conversations = conversations
    }

    func conversationForUsers(_ users: [User]) async -> Conversation? {
        // search in exsisting conversations
        for conversation in conversations {
            if conversation.users.count - 1 == users.count { // without current user
                var foundIt = true
                for user in users {
                    if !conversation.users.contains(user) {
                        foundIt = false
                        break
                    }
                }
                if foundIt {
                    return conversation
                }
            }
        }

        // create new one for group
        if users.count > 1 {
            return await createConversation(users)
        }

        // only create individual when first message is sent, not here (ConversationViewModel)
        return nil
    }

    func createConversation(_ users: [User]) async -> Conversation? {
        let pictureURL = await UploadingManager.uploadMedia(picture)
        return await createConversation(users, pictureURL)
    }

    private func createConversation(_ users: [User], _ pictureURL: URL?) async -> Conversation? {
        let dict: [String : Any] = [
            "users": users.map { $0.id } + [SessionManager.shared.currentUserId],
            "pictureURL": pictureURL?.absoluteString ?? "",
            "title": title
        ]

        return await withCheckedContinuation { continuation in
            var ref: DocumentReference? = nil
            ref = Firestore.firestore()
                .collection(Collection.conversations)
                .addDocument(data: dict) { err in
                    if let _ = err {
                        continuation.resume(returning: nil)
                    } else if let id = ref?.documentID {
                        continuation.resume(returning: Conversation(id: id, users: self.selectedUsers, pictureURL: pictureURL, title: self.title, latestMessage: nil))
                    }
                }
        }
    }
}
