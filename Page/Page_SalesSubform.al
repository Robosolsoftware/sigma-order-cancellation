pageextension 70706 SalesOrdSub extends "Sales Order Subform"
{
    layout
    {
        modify("Return Reason Code")
        {
            Visible = VisibleOnCancel;
            Caption = 'Cancel Reason Code';
        }
        // Add changes to page layout here
        addlast(Control1)
        {

            field(Cancelled; Rec.Cancelled)
            {
                Caption = 'SO Cancelled';
                ApplicationArea = All;
                Editable = false;
                Visible = VisibleOnCancel;
            }
            field("Cancelled By"; Rec."Cancelled By")
            {
                Caption = 'SO Cancelled By';
                ApplicationArea = All;
                Editable = false;
                Visible = VisibleOnCancel;
            }
            field("Cancelled Date"; Rec."Cancelled Date")
            {
                Caption = 'SO Cancellation Date';
                ApplicationArea = All;
                Editable = false;
                Visible = VisibleOnCancel;
            }
        }
        movebefore(Cancelled; "Return Reason Code")
    }

    actions
    {
        // Add changes to page actions here
        addafter("Dr&op Shipment")
        {

            group("Cancel Orders")
            {
                action("Cancel Order")
                {
                    Image = Cancel;
                    ApplicationArea = All;
                    Visible = VisibleOnCancel;
                    trigger OnAction()
                    var
                        L_SalesLine: Record "Sales Line";
                        ReleaseDoc: Codeunit "Release Sales Document";
                        WareShipLine: Record "Warehouse Shipment Line";
                        WareShipHeader: Record "Warehouse Shipment Header";
                        L_SalesHeader: Record "Sales Header";
                    begin

                        //Confirmation dailog box++
                        if not Confirm('Do you want to cancel this order', false) then
                            exit;
                        //Check Status Should Open++
                        if Rec."Return Reason Code" = '' then
                            Error('Please Select Cancel Reason Code');

                        L_SalesHeader.Reset();
                        L_SalesHeader.SetRange("Document Type", L_SalesLine."Document Type");
                        L_SalesHeader.SetRange("No.", L_SalesLine."Document No.");
                        if L_SalesHeader.FindFirst() then
                            L_SalesHeader.TestField(Status, L_SalesHeader.Status::Open);

                        Clear(L_SalesLine);
                        L_SalesLine := Rec;
                        CurrPage.SetSelectionFilter(L_SalesLine);
                        if L_SalesLine.FindSet() then begin
                            repeat
                                if L_SalesLine.Type = L_SalesLine.Type::Item then begin
                                    WareShipLine.Reset();
                                    WareShipLine.SETRANGE("Source Document", WareShipLine."Source Document"::"Sales Order");
                                    WareShipLine.SetRange("Source No.", L_SalesLine."Document No.");
                                    WareShipLine.SetRange("Location Code", L_SalesLine."Location Code");
                                    if WareShipLine.FindFirst() then begin
                                        Message('Unable to process ... Warehouse shipment exist for Order No. : %1 Line No. : %2', WareShipLine."Source No.", WareShipLine."Source Line No.");
                                        exit;
                                    end else begin
                                        if L_SalesLine.Cancelled = false then
                                            L_SalesLine.Validate("Original Order Quantity", L_SalesLine.Quantity);
                                        L_SalesLine.Validate(Quantity, L_SalesLine."Quantity Shipped");
                                        L_SalesLine.Cancelled := true;
                                        L_SalesLine."Cancelled By" := UserId;
                                        L_SalesLine."Cancelled Date" := Today;
                                        L_SalesLine.Modify();
                                    end;
                                end;
                            until L_SalesLine.Next() = 0;
                        end;
                        Message('Sales order is cancelled..');
                    end;
                }
            }


        }
    }

    trigger OnAfterGetCurrRecord()
    var
    begin
        Clear(VarPageEditFlag);
        if Rec.Cancelled then
            VarPageEditFlag := false
        else
            VarPageEditFlag := true;
    end;

    trigger OnOpenPage()
    begin
        clear(VisibleOnCancel);
        SalesRecSet.Get();
        if not SalesRecSet."Cancel Sales Order Feature" then
            VisibleOnCancel := false
        else
            VisibleOnCancel := true;
    end;

    var
        [InDataSet]
        VarPageEditFlag: Boolean;
        [InDataSet]
        VisibleOnCancel: Boolean;
        SalesRecSet: Record "Sales & Receivables Setup";
}