table 70701 "Error Log"
{
    Caption = 'Error Log';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = ToBeClassified;
        }
        field(2; "Clearance Error"; Text[500])
        {
            Caption = 'Clearance Error';
            DataClassification = ToBeClassified;
        }
        field(3; "Created Date"; Date)
        {
            Caption = 'Created Date';
            DataClassification = ToBeClassified;
        }
        field(4; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
        }
        field(5; "Document No."; Code[20])
        {

        }
        field(6; "Order Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = "Sales Order","Purchase Order";
        }


    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}