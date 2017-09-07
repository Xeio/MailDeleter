import com.GameInterface.DistributedValue;
import com.GameInterface.Tradepost;
import com.GameInterface.MailData;
import mx.utils.Delegate;
import com.Utils.Archive;

class MailDeleter
{    
	private var m_swfRoot: MovieClip;
	
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
		m_mailLimit = DistributedValue.Create("MailDeleter_MailLimit");
		m_mailLimit.SignalChanged.Connect(CheckMail, this);
		
		m_autoFetchMoney = DistributedValue.Create("MailDeleter_AutofetchMoney");
		m_autoFetchMoney.SignalChanged.Connect(CheckMail, this);
				
		Tradepost.SignalMailUpdated.Connect(CheckMail, this);
		Tradepost.SignalNewMail.Connect(UpdateMail, this);
		
		UpdateMail();
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
			if (!mailData.m_IsSendByTradepost) continue;
			if (!oldestMail || oldestMail.m_SendTime > mailData.m_SendTime)
			{
				oldestMail = mailData;
			}
			mailCounter++;
			if (m_autoFetchMoney.GetValue() != undefined && m_autoFetchMoney.GetValue() && mailData.m_Money > 0)
			{
				com.GameInterface.Chat.SignalShowFIFOMessage.Emit("Retrieving " + mailData.m_Money + " marks from mail.", 0);
				if (!mailData.m_IsRead)
				{
					mailData.m_IsRead = true;
					Tradepost.MarkAsRead(mailData.m_MailId);
				}
				Tradepost.GetMailItems(mailData.m_MailId);
				setTimeout(Delegate.create(this, CheckMail), 1000);				
				return;
			}
			
			if (m_mailLimit.GetValue() != undefined && m_mailLimit.GetValue() > 0 && mailCounter > m_mailLimit.GetValue() )
			{
				if (!oldestMail.m_IsRead)
				{
					//Forcibly set read flag, it doesn't get updated by the MarkAsRead call
					//If we dont set this, accidentally calling MarkAsRead on an already read mail will hard-lock the client
					oldestMail.m_IsRead = true;
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
	
	public function OnUnload()
	{		
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
}