report 70701 "Delete Inventory Picks"
{
    UsageCategory = ReportsAndAnalysis;
    ProcessingOnly = true;
    //ApplicationArea = All;

    dataset
    {
        dataitem("Warehouse Activity Header"; "Warehouse Activity Header")
        {
            RequestFilterFields = "No.";
            trigger OnAfterGetRecord()
            var
                L_WarehouseActivityHeader: Record "Warehouse Activity Header";
            begin
                L_WarehouseActivityHeader.Reset();
                L_WarehouseActivityHeader.SetRange("No.", "Warehouse Activity Header"."No.");
                L_WarehouseActivityHeader.SetRange(Type, "Warehouse Activity Header".Type);
                if L_WarehouseActivityHeader.FindFirst() then begin
                    L_WarehouseActivityHeader.Delete(true);
                    Commit();
                end;
            end;

            trigger OnPreDataItem()
            begin
                //"Contains TOS" Nothing but 'Pickable Items Exist'
                "Warehouse Activity Header".CalcFields("Contains TOS");
                "Warehouse Activity Header".SetRange("Contains TOS", false);
                "Warehouse Activity Header".SetRange(Type, "Warehouse Activity Header".Type::"Invt. Pick");
            end;
        }
    }

    // requestpage
    // {
    //     layout
    //     {
    //         area(Content)
    //         {
    //             group(Option)
    //             {
    //                 field(StartDate; StartDate)
    //                 {
    //                     ApplicationArea = All;
    //                     Caption = 'Enter Back Shipment Date Period';
    //                     ShowMandatory = true;

    //                     trigger OnValidate()
    //                     var
    //                         Var_DateFormula: DateFormula;
    //                     begin
    //                         Clear(Var_DateFormula);
    //                         Clear(EndDate);
    //                         if StartDate = Var_DateFormula then begin
    //                             Error('Back Shipment Date Period should not be blank');
    //                         end else
    //                             EndDate := 19990101D;
    //                     end;
    //                 }
    //                 field(EndDate; EndDate)
    //                 {
    //                     ApplicationArea = all;
    //                     Caption = 'End Date';
    //                     ShowMandatory = true;

    //                     trigger OnValidate()
    //                     var
    //                         Var_DateFormula: DateFormula;

    //                         Text_Date: Text;
    //                     begin
    //                         if EndDate <> 0D then begin
    //                             Clear(Var_DateFormula);
    //                             if StartDate = Var_DateFormula then
    //                                 Error('Back Shipment Date Period should not be blank');

    //                             Clear(Text_Date);
    //                             Text_Date := '-' + Format(StartDate);
    //                             if EndDate > CalcDate(Text_Date, WorkDate()) then
    //                                 Error('End Date should be less than %1', CalcDate(Text_Date, WorkDate()));
    //                         end;
    //                     end;
    //                 }
    //             }
    //         }
    //     }

    //     trigger OnQueryClosePage(CloseAction: Action): Boolean
    //     var
    //         Var_DateFormula: DateFormula;
    //     begin
    //         if CloseAction = CloseAction::OK then begin
    //             Clear(Var_DateFormula);
    //             if StartDate = Var_DateFormula then
    //                 Error('Back Shipment Date Period should not be blank');

    //             if EndDate = 0D then
    //                 Error('End Date should not be blank');
    //         end;
    //     end;
    // }
    var
        myInt: Integer;
        StartDate: DateFormula;
        EndDate: Date;
}