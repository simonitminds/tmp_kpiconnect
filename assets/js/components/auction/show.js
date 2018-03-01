import _ from 'lodash';
import React from 'react';
import { formatGMTDateTime, formatTimeRemaining, timeRemainingCountdown, formatTimeRemainingColor} from '../../utilities';
import moment from 'moment';
import  ServerDate from '../../serverdate';
import AuctionBreadCrumbs from './AuctionBreadCrumbs';
import AuctionHeader from './AuctionHeader';
import LowestBid from './LowestBid';
import BidList from './BidList';
import BiddingForm from './BiddingForm';
import MinimumBid from './MinimumBid';
import MostRecentBid from './MostRecentBid';
import InvitedSuppliers from './InvitedSuppliers';
import AuctionInvitation from './AuctionInvitation';


export default class AuctionShow extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      timeRemaining: timeRemainingCountdown(props.auction, moment().utc())
    }
  }

  componentDidMount() {
    this.timerID = setInterval(
      () => this.tick(),
      500
    );
  }

  componentWillUnmount() {
    clearInterval(this.timerID);
  }


  tick() {
    let time = moment(ServerDate.now()).utc();
    this.setState({
      timeRemaining: timeRemainingCountdown(this.props.auction, time)
    });
  }

  render() {
    const auction = this.props.auction;
    const currentUser = {
      isBuyer: parseInt(this.props.currentUserCompanyId) === auction.buyer.id
    };

    const additionInfoDisplay = (auction) => {
      if (auction.additional_information) {
        return auction.additional_information;
      } else {
        return <i>No additional information provided.</i>;
      }
    }

    const supplierBidComponents = (auction) => {
      return (
        <div  className="box">
          <MostRecentBid auction={auction} />
          <MinimumBid auction={auction} />
          <BiddingForm auction={auction} />
        </div>
      )

    }

    return (
      <div>
        <AuctionBreadCrumbs auction={auction} />
        <AuctionHeader auction={auction} timeRemaining={this.state.timeRemaining} />
        <section className="auction-page"> {/* Auction details */}
          <div className="container">
            <div className="auction-content">
              <div className="columns is-gapless">
                <div className="column is-two-thirds">
                  <div className="tabs is-fullwidth is-medium">
                    <ul>
                      <li className="is-active">
                        <h2 className="title is-size-5"><a className="has-text-left">Auction Monitor</a></h2>
                      </li>
                    </ul>
                  </div>
                  <LowestBid auction={auction} />
                  {currentUser.isBuyer ? <BidList auction={auction} /> : supplierBidComponents(auction) }
                </div>
                <div className="column is-one-third">
                  <div className="tabs is-fullwidth is-medium">
                    <ul>
                      <li className="is-active">
                        <h2 className="title is-size-5"><a>Auction Information</a></h2>
                      </li>
                      <li>
                        <h2 className="title is-size-5"><a>Messages</a></h2>
                      </li>
                    </ul>
                  </div>
                  { currentUser.isBuyer ? "" : <AuctionInvitation auction={auction} />}
                  {currentUser.isBuyer ? <InvitedSuppliers auction={auction} /> : "" }

                  <div className="box">
                    <div className="box__subsection">
                      <h3 className="box__header">Buyer Information
                        <div className="field is-inline-block is-pulled-right">
                          { currentUser.isBuyer ?
                            <a className="button is-primary is-small has-family-copy is-capitalized" href={`/auctions/${auction.id}/edit`}>Edit</a>
                            :
                            <div> </div>
                          }
                        </div>
                      </h3>
                      <ul className="list has-no-bullets">
                        <li>
                          <strong>Organization</strong> {auction.buyer.name}
                        </li>
                        <li>
                          <strong>Buyer</strong> Buyer Name
                        </li>
                        <li>
                          <strong>Buyer Reference Number</strong> BRN
                        </li>
                      </ul>
                    </div>
                    <div className="box__subsection">
                      <h3 className="box__header">Fuel Requirements</h3>
                      <ul className="list has-no-bullets">
                        <li>
                          <strong>{auction.fuel.name}</strong> {auction.fuel_quantity} MT
                        </li>
                      </ul>
                    </div>
                    <div className="box__subsection">
                      <h3 className="box__header">Port Information</h3>
                      <ul className="list has-no-bullets">
                        <li>
                          <strong className="is-block">{auction.port.name}</strong>
                          <span className="is-size-7"><strong>ETA</strong> {formatGMTDateTime(auction.eta)} GMT &ndash; <strong>ETD</strong> {formatGMTDateTime(auction.etd)} GMT</span>
                        </li>
                      </ul>
                    </div>
                    <div className="box__subsection">
                      <h3 className="box__header">Additional Information</h3>
                      <ul className="list has-no-bullets">
                        <li>
                          {additionInfoDisplay(auction)}
                      </li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    );
  }
}
