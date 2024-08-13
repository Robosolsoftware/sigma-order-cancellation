// pageextension 70711 "ROC Sales Order List" extends "Sales Order List"
// {
//     layout
//     {
//         addafter(Status)
//         {
//             field(Cancel; Rec.Cancel)
//             {
//                 ApplicationArea = All;
//                 Editable = false;
//                 Visible = VisibleOnCancel;
//             }
//         }
//     }

//     var
//         VisibleOnCancel: Boolean;
//         SalesRecSet: Record "Sales & Receivables Setup";

//     trigger OnOpenPage()
//     begin
//         Clear(VisibleOnCancel);
//         SalesRecSet.Get();
//         if not SalesRecSet."Cancel Sales Order Feature" then
//             VisibleOnCancel := false
//         else
//             VisibleOnCancel := true;
//     end;
// }