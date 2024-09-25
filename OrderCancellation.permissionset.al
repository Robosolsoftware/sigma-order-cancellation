permissionset 70700 OrderCancellation
{
    Assignable = true;
    Permissions = tabledata "Error Log" = RIMD,
        table "Error Log" = X,
        report "Cancel Back Sales Order" = X,
        codeunit ValidationOnCancelOrder = X,
        page "Cancel Order Setup" = X,
        page "Error Logs" = X;
}