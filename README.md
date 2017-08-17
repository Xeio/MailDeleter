# MailUtil

Adds a "Delete All" and "Take From All" buttons to the mail window that will delete any mail with no attachments, or take all money from mail.

Additionally provides two chat commands to set up automatic mail management tasks:

To have the add-on automatically delete mail over a certain amount use command "/setoption MailDeleter_MailLimit 10" where 10 is the limit. Setting the amount to 0 will disable auto-deletion.

To have the add-on automatically fetch money from mail use command "/setoption MailDeleter_AutofetchMoney true". This can be turned back off with command "/setoption MailDeleter_AutofetchMoney false".

