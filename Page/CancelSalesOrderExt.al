pageextension 70701 CancelSOOrder extends "Sales Order"
{
    layout
    {
        // Add changes to page layout here
        addafter("Due Date")
        {
            field(Cancel; Rec.Cancel)
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
        modify("Invoice Details")
        {
            Editable = VarPageEditFlag;
        }
        modify(General)
        {
            Editable = VarPageEditFlag;
        }
        modify("Foreign Trade")
        {
            Editable = VarPageEditFlag;
        }
        

    }

    actions
    {
        addafter(Release)
        {

            action("Cancel Order")
            {

                Image = Cancel;
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                Visible = VisibleOnCancel;
                trigger OnAction()
                var
                    L_SalesLine: Record "Sales Line";
                    WareShipLine: Record "Warehouse Shipment Line";
                    WareShipHeader: Record "Warehouse Shipment Header";
                    ReleaseDoc: Codeunit "Release Sales Document";
                    TakeWhseActvityLine: Record "Warehouse Activity Line";
                    ReleaseWhseShptDoc: Codeunit "Whse.-Shipment Release";
                    Canceled: Boolean;
                    ArchiveManagement: Codeunit ArchiveManagement;

                begin

                    //Abdul+++++
                    //Confirmation dailog box++

                    SalesRecSet.Get();
                    if not SalesRecSet."Cancel Sales Order Feature" then begin
                        Message('Enable Cancel Sales order feature on Sales & Receivable setup to unlock this feature');
                        exit;
                    end;

                    if not Confirm('Do you want to cancel this order', false) then
                        exit;

                    L_SalesLine.Reset();
                    L_SalesLine.SetRange("Document Type", Rec."Document Type");
                    L_SalesLine.SetRange("Document No.", Rec."No.");
                    L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                    if L_SalesLine.FindSet() then begin
                        repeat
                            if L_SalesLine."Return Reason Code" = '' then begin
                                Error('Please Select Cancel Reason Code for Product: %1', L_SalesLine."No.");
                            end;
                        until L_SalesLine.Next = 0;
                    end;



                    //Check Status++
                    Rec.TestField(Status, Rec.Status::Open);

                    //Chcek Warehouse Shipment exists



                    Clear(L_SalesLine);
                    L_SalesLine.Reset();
                    L_SalesLine.SetRange("Document Type", Rec."Document Type");
                    L_SalesLine.SetRange("Document No.", Rec."No.");
                    L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                    if L_SalesLine.FindSet() then
                        repeat
                            WareShipLine.Reset();
                            WareShipLine.SETRANGE("Source Document", WareShipLine."Source Document"::"Sales Order");
                            WareShipLine.SetRange("Source No.", Rec."No.");
                            if WareShipLine.FindFirst() then begin
                                Message('Unable to process ... Warehouse shipment exist for Order No. : %1 Line No. : %2', WareShipLine."Source No.", WareShipLine."Source Line No.");
                                exit;
                            end;
                        until L_SalesLine.Next() = 0;

                    //Update Sales Line Quantity+++
                    L_SalesLine.Reset();
                    L_SalesLine.SetRange("Document Type", L_SalesLine."Document Type"::Order);
                    L_SalesLine.SetRange("Document No.", Rec."No.");
                    L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                    if L_SalesLine.FindSet() then begin
                        repeat
                            if L_SalesLine.Cancelled = false then//new changes
                                L_SalesLine.Validate("Original Order Quantity", L_SalesLine.Quantity);
                            L_SalesLine.Validate(Quantity, L_SalesLine."Quantity Shipped");
                            L_SalesLine.Cancelled := true;
                            L_SalesLine."Cancelled By" := UserId;
                            L_SalesLine."Cancelled Date" := Today;
                            L_SalesLine.Modify();
                        until L_SalesLine.Next() = 0;
                        Rec.Cancel := true;
                        Rec."Cancelled By" := UserId;
                        Rec."Cancelled Date" := Today;
                        Rec.Modify();
                    end;
                    Message('Sales order is cancelled..');
                end;
            }
        }
    }
    trigger OnAfterGetCurrRecord()
    var
    begin
        Clear(VarPageEditFlag);

        if Rec.Cancel then
            VarPageEditFlag := false
        else
            VarPageEditFlag := true;

    end;

    trigger OnOpenPage()
    begin
        Clear(VisibleOnCancel);
        SalesRecSet.Get();
        if not SalesRecSet."Cancel Sales Order Feature" then
            VisibleOnCancel := false
        else
            VisibleOnCancel := true;

    end;

    var
        [InDataSet]
        VarPageEditFlag: Boolean;//Azhar
        [InDataSet]
        VisibleOnCancel: Boolean;
        SalesRecSet: Record "Sales & Receivables Setup";
}