import com.GameInterface.DistributedValue;
import com.GameInterface.Tradepost;
import com.GameInterface.MailData;
import mx.utils.Delegate;
import com.Utils.Archive;

class MailDeleter
{    
	private var m_swfRoot: MovieClip;
	
	private var m_deleteAllButton: MovieClip
	private var m_confirmDeleteAllPrompt: MovieClip
	
	private var m_tradepostCommand:DistributedValue;	
	
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
		
		if (m_tradepostCommand.GetValue())
		{
			setTimeout(Delegate.create(this, AddUIElements), 1000);
		}
	}
	
	function TradePostOpened()
	{
		if (m_tradepostCommand.GetValue())
		{
			setTimeout(Delegate.create(this, AddUIElements), 1000);
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
	
	public function OnUnload()
	{
		m_confirmDeleteAllPrompt.SignalPromptResponse.Disconnect(OnConfirmDeleteAllClicked, this);
		m_confirmDeleteAllPrompt.removeMovieClip();
		m_confirmDeleteAllPrompt = undefined;
		
		m_deleteAllButton.removeEventListener("click", this, "OnDeleteAllClick");
		m_deleteAllButton.removeMovieClip();
		m_deleteAllButton = undefined;
		
		m_tradepostCommand.SignalChanged.Disconnect(TradePostOpened, this);
		m_tradepostCommand = undefined;
	}
	
	public function Activate(config: Archive)
	{
	}
	
	public function Deactivate(): Archive
	{
		var archive: Archive = new Archive();			
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
	}
	
	public function OnDeleteAllClick()
	{
		m_confirmDeleteAllPrompt.ShowPrompt(false);
		m_confirmDeleteAllPrompt.m_Title.text = "DELETE ALL MAIL";
		m_confirmDeleteAllPrompt.m_Message.htmlText = "Are you sure you want to all mail items without attachments?";
	}
	
	public function OnConfirmDeleteAllClicked()
	{
		DeleteMail();
	}
}