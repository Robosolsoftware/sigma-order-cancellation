tableextension 70703 PurchInvHeader_Ext_RoboCancel extends "Purch. Inv. Header"
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

    }
}
