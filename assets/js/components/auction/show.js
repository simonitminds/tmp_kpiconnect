import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime, timeRemainingCountdown} from '../../utilities';
import moment from 'moment';
import  ServerDate from '../../serverdate';
import AuctionBreadCrumbs from './AuctionBreadCrumbs';
import AuctionHeader from './AuctionHeader';
import BuyerWinningBid from './BuyerWinningBid';
import BuyerBestSolution from './BuyerBestSolution';
import SupplierWinningBid from './SupplierWinningBid';
import BuyerBidList from './BuyerBidList';
import SupplierBidList from './SupplierBidList';
import BiddingForm from './BiddingForm';
import MinimumBid from './MinimumBid';
import MostRecentBid from './MostRecentBid';
import InvitedSuppliers from './InvitedSuppliers';
import AuctionInvitation from './AuctionInvitation';


export default class AuctionShow extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      timeRemaining: timeRemainingCountdown(props.auctionPayload, moment().utc())
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
      timeRemaining: timeRemainingCountdown(this.props.auctionPayload, time)
    });
  }

  render() {
    const auctionPayload = this.props.auctionPayload;
    const auctionState = this.props.auctionPayload.state;
    const auction = this.props.auctionPayload.auction;
    const currentUser = {
      isBuyer: parseInt(this.props.currentUserCompanyId) === auction.buyer_id
    };

    const additionInfoDisplay = (auction) => {
      if (auction.additional_information) {
        return auction.additional_information;
      } else {
        return <i>No additional information provided.</i>;
      }
    }


    const buyerBidComponents = () => {
      if (auctionState.status == 'decision' || auctionState.status == 'closed') {
        return (
          <div>
            <BuyerBestSolution auctionPayload={auctionPayload} />
            <BuyerBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else if (auctionState.status != 'pending') {
        return (
          <div>
            <BuyerWinningBid auctionPayload={auctionPayload} />
            <BuyerBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else {
        return (
          <div className = "auction-notification box is-gray-0" >
            <h3 className="has-text-weight-bold is-flex">
            <span className="is-inline-block qa-supplier-bid-status-message">The auction has not started yet</span>
            </h3>
          </div>
        )
      }
    }

    const supplierBidComponents = () => {
      if (auctionState.status == 'open') {
        return (
          <div>
            <SupplierWinningBid auctionPayload={auctionPayload} />
            <BiddingForm formSubmit={this.props.formSubmit} auction={auction} />
            <SupplierBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else if (auctionState.status != 'pending') {
        return (
          <div>
            <SupplierWinningBid auctionPayload={auctionPayload} />
            <SupplierBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else {
        return (
          <div className = "auction-notification box is-gray-0" >
            <h3 className="has-text-weight-bold is-flex">
            <span className="is-inline-block qa-supplier-bid-status-message">The auction has not started yet</span>
            </h3>
          </div>
        )
      }
    }

    return (
      <div>
        <AuctionBreadCrumbs auction={auction} />
        <AuctionHeader auctionPayload={auctionPayload} timeRemaining={this.state.timeRemaining} />
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
                  { currentUser.isBuyer ? buyerBidComponents() : supplierBidComponents() }
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
                  { currentUser.isBuyer ? "" : <AuctionInvitation auction={auction} /> }
                  { currentUser.isBuyer ? <InvitedSuppliers auction={auction} /> : "" }

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
                          <span className="is-size-7"><strong>ETA</strong> {formatUTCDateTime(auction.eta)} GMT &ndash; <strong>ETD</strong> {formatUTCDateTime(auction.etd)} GMT</span>
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
