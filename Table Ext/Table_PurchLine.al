tableextension 70704 PurchLine extends "Purchase Line"
{
    fields
    {
        // Add changes to table fields here

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
            Caption = 'Cancel Reason Code';
        }
        modify(Quantity)
        {
            trigger OnAfterValidate()
            begin
                if Rec.Type = Rec.Type::Item then begin
                    Rec."Original Order Quantity" := Rec.Quantity;
                end;
            end;
        }
    }

    var
        myInt: Integer;
}