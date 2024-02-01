tableextension 70715 "ROC Sales Line Archive " extends "Sales Line Archive"
{
    fields
    {
        // Add changes to table fields here
        field(70700; Cancelled; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(70701; "Cancelled By"; Code[100])
        {
            DataClassification = ToBeClassified;
        }
        field(70702; "Cancelled Date"; Date)
        {
            DataClassification = ToBeClassified;
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

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}