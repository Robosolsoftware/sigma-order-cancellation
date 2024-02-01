tableextension 70701 SalesLineExt1 extends "Sales Line"
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
        //Cancel Order --
        modify(Quantity)
        {
            trigger OnAfterValidate()
            begin
                if (Rec.Type = Rec.Type::Item) and (rec."No." <> '') and (rec.Quantity <> xRec.Quantity) then begin
                    Rec."Original Order Quantity" := Rec.Quantity;
                end;
            end;
        }

    }

    var
        myInt: Integer;
}