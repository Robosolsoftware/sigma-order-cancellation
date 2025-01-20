permissionset 70700 OrderCancellation
{
    Assignable = true;
    Permissions = tabledata "Error Log" = RIMD,
        table "Error Log" = X,
        report "Cancel Back Sales Order" = X,
        codeunit ValidationOnCancelOrder = X,
        page "Cancel Order Setup" = X,
        page "Error Logs" = X,
        report "Cancel Purchase Order" = X,
        report "Cancel Non-IRP Orders" = X;
}