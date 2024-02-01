tableextension 70714 "ROC Sales Header Archive" extends "Sales Header Archive"
{
    fields
    {
        // Add changes to table fields here
        field(70700; Cancel; Boolean)
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