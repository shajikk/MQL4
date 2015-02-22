//#include <stderror.mqh>
//#include <WinUser32.mqh>
//#include <stdlib.mqh>
//if you include this file in the line above in the global area then your switch can actually say:
//case ERR_PRICE_CHANGED: instead of case 135:

void exitbuys()
{
  for (int i=OrdersTotal()-1; i >=0; i--)
  {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
    {
      if (OrderType() == OP_BUY && OrderMagicNumber()==MagicNumber)
      {
        while(true)//infinite loop must be escaped by break
        {
          bool result = OrderClose(OrderTicket(), OrderLots(), Bid, 3, Red);//actual order closing
          if (result != true)//if it did not close
          {
            int err = GetLastError(); Print("LastError = ",err);//get the reason why it didn't close
          }
          else {err = 0;break;}//if it did close it breaks out of while early DOES NOT RUN SWITCH
          switch(err)
          {
            case 129://INVALID_PRICE //if it was 129 it will run every line until it gets to the break.
            case 135://ERR_PRICE_CHANGED//same for 135
            case 136://ERR_OFF_QUOTES//and 136
            case 137://ERR_BROKER_BUSY//and 137
            case 138://ERR_REQUOTE//and 138
            case 146:Sleep(1000);RefreshRates();i++;break;//Sleeps,Refreshes and increments.Then breaks out of switch.
            default:break;//if the err does not match any of the above. It does not increment. and runs next order in series.
          }
          break;//after breaking out of switch it breaks out of while loop. which order it runs next depends on i++ or not.
        }
      }
    }
    else Print( "When selecting a trade, error ",GetLastError()," occurred");
  }
}

