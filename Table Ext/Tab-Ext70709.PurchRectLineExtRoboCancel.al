tableextension 70709 PurchRectLine_Ext_RoboCancel extends "Purch. Rcpt. Line"
{
    fields
    {
        field(70700; "PO Cancelled"; Boolean)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(70701; "PO Cancellation Date"; Date)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(70702; "PO Cancelled By"; Code[100])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(70703; "Original Order Quantity"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
    }
}
