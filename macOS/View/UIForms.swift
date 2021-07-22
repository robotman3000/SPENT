//
//  UIForms.swift
//  macOS
//
//  Created by Eric Nims on 7/22/21.
//

import SwiftUI
import SwiftUIKit

enum UIForms: SheetProvider {
    case account(context: SheetContext, account: Bucket?, onSubmit: (_ data: inout Bucket) -> Void)
    case bucket(context: SheetContext, bucket: Bucket?, onSubmit: (_ data: inout Bucket) -> Void)
    case accountBucket(context: SheetContext, contextAccount: Bucket, onSubmit: (_ data: inout Bucket) -> Void)
    case transaction(context: SheetContext, transaction: Transaction?, contextBucket: Bucket, onSubmit: (_ data: inout Transaction) -> Void)
    case transfer(context: SheetContext, transaction: Transaction?, contextBucket: Bucket, onSubmit: (_ data: inout Transaction) -> Void)
    case tag(context: SheetContext, tag: Tag?, onSubmit: (_ data: inout Tag) -> Void)
    case schedule(context: SheetContext, schedule: Schedule?, onSubmit: (_ data: inout Schedule) -> Void)
    case transactionTags(context: SheetContext, transaction: Transaction, currentTags: Set<Tag>, onSubmit: (_ tags: [Tag], _ transaction: Transaction) -> Void)

    var sheet: AnyView {
        switch self {
        case .account(context: let context, account: let account, onSubmit: let handleSubmit):
            if let acc = account {
                return AccountForm(bucket: acc, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            } else {
                return AccountForm(onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            }
        case .bucket(context: let context, bucket: let bucket, onSubmit: let handleSubmit):
            if let buk = bucket {
                return BucketForm(bucket: buk, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            } else {
                return BucketForm(onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            }
        case .accountBucket(context: let context, contextAccount: let account, onSubmit: let handleSubmit):
            return BucketForm(selected: ObservableStructWrapper(wrappedStruct: account), onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
        case .transaction(context: let context, transaction: let transaction, contextBucket: let bucket, onSubmit: let handleSubmit):
            if let trans = transaction {
                return TransactionForm(transaction: trans, currentBucket: bucket, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            } else {
                return TransactionForm(currentBucket: bucket, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            }
        case .transfer(context: let context, transaction: let transaction, contextBucket: let bucket, onSubmit: let handleSubmit):
            if let trans = transaction {
                return TransferForm(transaction: trans, currentBucket: bucket, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            } else {
                return TransferForm(currentBucket: bucket, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            }
        case .tag(context: let context, tag: let tag, onSubmit: let handleSubmit):
            if let t = tag {
                return TagForm(tag: t, onSubmit: handleSubmit, onCancel: { context.dismiss() } ).padding().any()
            } else {
                return TagForm(onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            }
        case .schedule(context: let context, schedule: let schedule, onSubmit: let handleSubmit):
            if let sch = schedule {
                return ScheduleForm(schedule: sch, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            } else {
                return ScheduleForm(onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            }
        case .transactionTags(context: let context, transaction: let transaction, currentTags: let currentTags, onSubmit: let handleSubmit):
            return TransactionTagForm(transaction: transaction, tags: currentTags, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
        }
    }
}
