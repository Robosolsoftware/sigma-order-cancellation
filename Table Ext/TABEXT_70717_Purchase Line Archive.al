tableextension 70717 "ROC Purchase Line Archive" extends "Purchase Line Archive"
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
        field(70704; "Cancel Reason code"; Code[20])
        {
            TableRelation = "Return Reason";
        }
    }
}