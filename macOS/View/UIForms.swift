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
    case bucket(context: SheetContext, bucket: Bucket?, parent: Bucket?, parentChoices: [Bucket], budgetChoices: [Schedule], onSubmit: (_ data: inout Bucket) -> Void)
    case transaction(context: SheetContext, transaction: Transaction?, contextBucket: Bucket, bucketChoices: [Bucket], onSubmit: (_ data: inout Transaction) -> Void)
    case transfer(context: SheetContext, transaction: Transaction?, contextBucket: Bucket, sourceChoices: [Bucket], destChoices: [Bucket], onSubmit: (_ data: inout Transaction) -> Void)
    case tag(context: SheetContext, tag: Tag?, onSubmit: (_ data: inout Tag) -> Void)
    case schedule(context: SheetContext, schedule: Schedule?, markerChoices: [Tag], onSubmit: (_ data: inout Schedule) -> Void)
    case transactionTags(context: SheetContext, transaction: Transaction, tagChoices: [Tag], onSubmit: (_ tags: [Tag], _ transaction: Transaction) -> Void)
    case splitTransaction(context: SheetContext, splitMembers: [Transaction], contextBucket: Bucket, sourceChoices: [Bucket], destChoices: [Bucket], onSubmit: (_ data: inout [Transaction]) -> Void)
    case confirmDelete(context: SheetContext, message: String, onConfirm: () -> Void)
    
    var sheet: AnyView {
        switch self {
        case .account(context: let context, account: var account, onSubmit: let handleSubmit):
            if account == nil{
                account = Bucket.newBucket()
            }
            return AccountForm(account: account!, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            
        case .bucket(context: let context, bucket: var bucket, parent: let parent, parentChoices: let parentChoices, budgetChoices: let budgetChoices, onSubmit: let handleSubmit):
            if bucket == nil{
                bucket = Bucket.newBucket()
            }
            return BucketForm(bucket: bucket!, parent: parent, parentChoices: parentChoices, budgetChoices: budgetChoices, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            
        case .transaction(context: let context, transaction: var transaction, contextBucket: let bucket, bucketChoices: let bucketChoices, onSubmit: let handleSubmit):
            if transaction == nil {
                transaction = Transaction.newTransaction()
            }
            return TransactionForm(transaction: transaction!, selectedBucket: bucket, bucketChoices: bucketChoices, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            
        case .transfer(context: let context, transaction: var transaction, contextBucket: _, sourceChoices: let sourceChoices, destChoices: let destChoices, onSubmit: let handleSubmit):
            if transaction == nil {
                transaction = Transaction.newTransaction()
            }
            return TransferForm(transaction: transaction!, sourceChoices: sourceChoices, destinationChoices: destChoices, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            
        case .tag(context: let context, tag: var tag, onSubmit: let handleSubmit):
            if tag == nil {
                tag = Tag.newTag()
            }
            return TagForm(tag: tag!, onSubmit: handleSubmit, onCancel: { context.dismiss() } ).padding().any()
            
        case .schedule(context: let context, schedule: var schedule, markerChoices: let markerChoices, onSubmit: let handleSubmit):
            if schedule == nil {
                schedule = Schedule.newSchedule()
            }
            return ScheduleForm(schedule: schedule!, markerChoices: markerChoices, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            
        case .transactionTags(context: let context, transaction: let transaction, tagChoices: let tagChoices, onSubmit: let handleSubmit):
            return TransactionTagForm(transaction: transaction, tagChoices: tagChoices, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            
        case .splitTransaction(context: let context, splitMembers: let members, contextBucket: _, sourceChoices: let sourceChoices, destChoices: let destChoices, onSubmit: let handleSubmit):
            var head: Transaction?
            var newMembers: [Transaction] = []
            
            for member in members {
                // Only the head will have this type
                if member.type == .Split {
                    head = member
                } else {
                    newMembers.append(member)
                }
            }
            
            if head == nil {
                head = Transaction.newSplitTransaction()
            }
            
            return SplitTransactionForm(head: head!, bucketChoices: sourceChoices, splitMembers: newMembers, sourceChoices: sourceChoices, destinationChoices: destChoices, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            
        case .confirmDelete(context: let context, message: _, onConfirm: let onConfirm):
            return VStack{
                Text("Are you sure you want to delete this?")
            }.toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { context.dismiss() })
                }
                ToolbarItem(placement: .destructiveAction){
                    Button("Confirm", action: { context.dismiss(); onConfirm() })
                }
            }).padding().any()
        }
    }
}
