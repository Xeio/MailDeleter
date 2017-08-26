import com.GameInterface.DistributedValue;
import com.GameInterface.Tradepost;
import com.GameInterface.MailData;
import mx.utils.Delegate;
import com.Utils.Archive;

class MailDeleter
{    
	private var m_swfRoot: MovieClip;
	
	private var m_deleteAllButton: MovieClip
	private var m_takeMoneyButton: MovieClip
	private var m_confirmDeleteAllPrompt: MovieClip
	
	private var m_tradepostCommand:DistributedValue;
	private var m_mailLimit:DistributedValue;
	private var m_autoFetchMoney:DistributedValue;
	
	public static function main(swfRoot:MovieClip):Void 
	{
		var bagUtil = new MailDeleter(swfRoot);
		
		swfRoot.onLoad = function() { bagUtil.OnLoad(); };
		swfRoot.OnUnload =  function() { bagUtil.OnUnload(); };
		swfRoot.OnModuleActivated = function(config:Archive) { bagUtil.Activate(config); };
		swfRoot.OnModuleDeactivated = function() { return bagUtil.Deactivate(); };
	}
	
    public function MailDeleter(swfRoot: MovieClip) 
    {
		m_swfRoot = swfRoot;
    }
	
	public function OnLoad()
	{
		m_tradepostCommand = DistributedValue.Create("tradepost_window");
		m_tradepostCommand.SignalChanged.Connect(TradePostOpened, this);
		
		m_mailLimit = DistributedValue.Create("MailDeleter_MailLimit");
		m_mailLimit.SignalChanged.Connect(CheckMail, this);
		
		m_autoFetchMoney = DistributedValue.Create("MailDeleter_AutofetchMoney");
		m_autoFetchMoney.SignalChanged.Connect(CheckMail, this);
		
		if (m_tradepostCommand.GetValue())
		{
			setTimeout(Delegate.create(this, AddUIElements), 500);
		}
		
		Tradepost.SignalMailUpdated.Connect(CheckMail, this);
		Tradepost.SignalNewMail.Connect(UpdateMail, this);
		
		UpdateMail();
	}
	
	function TradePostOpened()
	{
		if (m_tradepostCommand.GetValue())
		{
			setTimeout(Delegate.create(this, AddUIElements), 500);
		}
	}
	
	function UpdateMail()
	{
		Tradepost.UpdateMail();
	}
	
	function CheckMail(mailID)
	{
		var oldestMail:MailData;
		var mailCounter:Number = 0;
		for (var i in Tradepost.m_Mail)
		{
			var mailData:MailData = Tradepost.m_Mail[i];
			if (!oldestMail || oldestMail.m_SendTime > mailData.m_SendTime)
			{
				oldestMail = mailData;
			}
			mailCounter++;
			if (m_autoFetchMoney.GetValue() != undefined && m_autoFetchMoney.GetValue() && mailData.m_Money > 0)
			{
				com.GameInterface.Chat.SignalShowFIFOMessage.Emit("Retrieving " + mailData.m_Money + " marks from mail.", 0);
				Tradepost.GetMailItems(mailData.m_MailId);
				setTimeout(Delegate.create(this, CheckMail), 1000);				
				return;
			}
			
			if (m_mailLimit.GetValue() != undefined && m_mailLimit.GetValue() > 0 && mailCounter > m_mailLimit.GetValue() )
			{
				if (!oldestMail.m_IsRead)
				{
					Tradepost.MarkAsRead(oldestMail.m_MailId);
					setTimeout(Delegate.create(this, CheckMail), 1000);				
					return;
				}
				if (!oldestMail.m_HasItems && oldestMail.m_Money == 0)
				{
					Tradepost.DeleteMail(oldestMail.m_MailId);
					setTimeout(Delegate.create(this, CheckMail), 1000);				
					return;
				}
			}
		}
	}
	
	function DeleteMail()
	{
		for (var i in Tradepost.m_Mail)
		{
			var mailData:MailData = Tradepost.m_Mail[i];
			if (!mailData.m_HasItems && mailData.m_Money == 0)
			{
				Tradepost.DeleteMail(mailData.m_MailId);
				setTimeout(Delegate.create(this, DeleteMail), 200);
				return;
			}
		}
	}
	
	function TakeAllMoney()
	{
		for (var i in Tradepost.m_Mail)
		{
			var mailData:MailData = Tradepost.m_Mail[i];
			if (mailData.m_Money > 0)
			{
				com.GameInterface.Chat.SignalShowFIFOMessage.Emit("Retrieving " + mailData.m_Money + " marks from mail.", 0);
				Tradepost.GetMailItems(mailData.m_MailId);
				setTimeout(Delegate.create(this, TakeAllMoney), 200);
				return;
			}
		}
	}
	
	public function OnUnload()
	{
		m_confirmDeleteAllPrompt.SignalPromptResponse.Disconnect(OnConfirmDeleteAllClicked, this);
		m_confirmDeleteAllPrompt.removeMovieClip();
		m_confirmDeleteAllPrompt = undefined;

		m_deleteAllButton.removeEventListener("click", this, "OnDeleteAllClick");
		m_deleteAllButton.removeMovieClip();
		m_deleteAllButton = undefined;
		
		m_takeMoneyButton.removeEventListener("click", this, "TakeAllMoney");
		m_takeMoneyButton.removeMovieClip();
		m_takeMoneyButton = undefined;

		m_tradepostCommand.SignalChanged.Disconnect(TradePostOpened, this);
		m_tradepostCommand = undefined;
		
		m_mailLimit.SignalChanged.Disconnect(CheckMail, this);
		m_mailLimit = undefined;
		
		m_autoFetchMoney.SignalChanged.Disconnect(CheckMail, this);
		m_autoFetchMoney = undefined;
		
		Tradepost.SignalMailUpdated.Disconnect(CheckMail, this);
		Tradepost.SignalNewMailNotification.Disconnect(CheckMail, this);
	}
	
	public function Activate(config: Archive)
	{
		m_autoFetchMoney.SetValue(config.FindEntry("Autofetch", false));
		m_mailLimit.SetValue(config.FindEntry("MailLimit", undefined));
	}
	
	public function Deactivate(): Archive
	{
		var archive: Archive = new Archive();
		archive.AddEntry("Autofetch", m_autoFetchMoney.GetValue());
		archive.AddEntry("MailLimit", m_mailLimit.GetValue());
		return archive;
	}
	
	private function AddUIElements()
	{
		var x = _root.tradepost.m_Window.m_Content.m_ViewsContainer.m_PostalServiceView.m_ReadMailHeader;
		
		m_confirmDeleteAllPrompt = x.attachMovie("ConfirmDeleteMailPromptWindow", "m_confirmDeleteAllPrompt", x.getNextHighestDepth());
		m_confirmDeleteAllPrompt.SignalPromptResponse.Connect(OnConfirmDeleteAllClicked, this);

		m_deleteAllButton = x.attachMovie("DeleteMailButton", "m_deleteAllButton", x.getNextHighestDepth());
		m_deleteAllButton.autoSize = "left";
		m_deleteAllButton.label = "DELETE ALL";
		m_deleteAllButton._y = 2;
		m_deleteAllButton._x = x.m_DeleteMailButton._x - m_deleteAllButton._width - 10;
		m_deleteAllButton.disableFocus = true;
		m_deleteAllButton.addEventListener("click", this, "OnDeleteAllClick");
		
		m_takeMoneyButton = x.attachMovie("TakeAllAttachmentsButton", "m_takeMoneyButton", x.getNextHighestDepth());
        m_takeMoneyButton.autoSize = "left";
        m_takeMoneyButton.label = "TAKE FROM ALL";
		m_takeMoneyButton._y = 2;
        m_takeMoneyButton._x = m_deleteAllButton._x - m_takeMoneyButton._width - 10 - 20;
        m_takeMoneyButton.disableFocus = true;
        m_takeMoneyButton.addEventListener("click", this, "TakeAllMoney");
	}
	
	public function OnDeleteAllClick()
	{
		m_confirmDeleteAllPrompt.ShowPrompt(false);
		m_confirmDeleteAllPrompt.m_Title.text = "DELETE ALL MAIL";
		m_confirmDeleteAllPrompt.m_Message.htmlText = "Are you sure you want to delete all mail items without attachments?";
	}
	
	public function OnConfirmDeleteAllClicked()
	{
		DeleteMail();
	}
}