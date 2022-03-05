//
//  UIForms.swift
//  macOS
//
//  Created by Eric Nims on 7/22/21.
//

import SwiftUI
import SwiftUIKit

enum FormKeys: SheetProvider {
    case account(context: SheetContext, account: Account?)
    case bucket(context: SheetContext, bucket: Bucket?)
    case transaction(context: SheetContext, transaction: Transaction?)
    case transfer(context: SheetContext, transfer: Transfer?)
//    case tag(context: SheetContext, tag: Tag?)
//    //case schedule(context: SheetContext, schedule: Schedule?, onSubmit: (_ data: inout Schedule) -> Void)
//    case transactionTags(context: SheetContext, transaction: Transaction)
    case splitTransaction(context: SheetContext, split: SplitTransaction?)
//    case transactionTemplate(context: SheetContext, template: DBTransactionTemplate?)
//    case documentList(context: SheetContext, transaction: Transaction)
    case confirmDelete(context: SheetContext, message: String, onConfirm: () -> Void)
    case confirmAction(context: SheetContext, message: String, onConfirm: () -> Void, onCancel: () -> Void)
    case manageBuckets(context: SheetContext)
    case manageDatabase(context: SheetContext)
    
    var sheet: AnyView {
        switch self {
        case let .account(context: context, account: account):
            return AccountForm(model: AccountFormModel(account ?? Account(name: "")),
                                onSubmit: { context.dismiss() }, onCancel: { context.dismiss() }).any()
            
        case let .bucket(context: context, bucket: bucket):
            return BucketForm(model: BucketFormModel(bucket: bucket ?? Bucket(name: "")),
                                onSubmit: { context.dismiss() }, onCancel: { context.dismiss() }).any()
            
        case let .transaction(context: context, transaction: transaction):
            return TransactionForm(model: TransactionFormModel(transaction:
            transaction ?? Transaction(id: nil, status: .Uninitiated, amount: 0, payee: "", memo: "", entryDate: Date(), postDate: nil, bucketID: nil, accountID: -1)),
                                onSubmit: { context.dismiss() }, onCancel: { context.dismiss() }).any()
            
        case let .transfer(context: context, transfer: transfer):
            let model = TransferFormModel(transfer: transfer)
            return TransferForm(model: model,
                                onSubmit: { context.dismiss() }, onCancel: { context.dismiss() }).any()
//            
//        case .tag(context: let context, tag: var tag):
//            if tag == nil {
//                tag = Tag.newTag()
//            }
//            return TagForm(model: TagFormModel(tag: tag!),
//                           onSubmit: { context.dismiss() }, onCancel: { context.dismiss() } ).any()
//            
////        case .schedule(context: let context, schedule: var schedule, onSubmit: let handleSubmit):
////            if schedule == nil {
////                schedule = Schedule.newSchedule()
////            }
////            return EmptyView().any()
////            //return ScheduleForm(schedule: schedule!, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
//            
//        case .transactionTags(context: let context, transaction: let transaction):
//            return TransactionTagForm(model: TransactionTagFormModel(transaction: transaction),
//                                onSubmit: { context.dismiss() }, onCancel: { context.dismiss() }).any()
//            
//        case .transactionTemplate(context: let context, template: var template):
//            if template == nil {
//                template = DBTransactionTemplate.newTemplate()
//            }
//            return TemplateForm(model: TemplateFormModel(template: template!),
//                                onSubmit: { context.dismiss() }, onCancel: { context.dismiss() }).any()
//            
        case let .splitTransaction(context: context, split: split):
            return SplitTransactionForm(model: SplitTransactionFormModel(model: split),
                                        onSubmit: { context.dismiss() }, onCancel: { context.dismiss() }).any()
//        
//        case .documentList(context: let context, transaction: let transaction):
//            return DocumentListView(transaction: transaction).toolbar(content: {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Done", action: { context.dismiss() })
//                }
//            }).padding().any()

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
        
        case .confirmAction(context: let context, message: let message, onConfirm: let onConfirm, onCancel: let onCancel):
            return VStack{
                Text(message)
            }.toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { context.dismiss(); onCancel() })
                }
                ToolbarItem(placement: .destructiveAction){
                    Button("Confirm", action: { context.dismiss(); onConfirm() })
                }
            }).padding().any()
        case let .manageBuckets(context: context):
            return BucketManagerView().toolbar(content: {
                ToolbarItem(placement: .confirmationAction){
                    Button("Done", action: { context.dismiss() })
                }
            }).any()
        case let .manageDatabase(context: context):
            return DatabaseManagerView().toolbar(content: {
                ToolbarItem(placement: .confirmationAction){
                    Button("Done", action: { context.dismiss() })
                }
            }).any()
        }
    }
}
