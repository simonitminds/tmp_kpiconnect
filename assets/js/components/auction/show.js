import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime, timeRemainingCountdown} from '../../utilities';
import moment from 'moment';
import ServerDate from '../../serverdate';
import AuctionBreadCrumbs from './auction-bread-crumbs';
import AuctionHeader from './auction-header';
import BuyerLowestBid from './buyer-lowest-bid';
import BuyerBestSolution from './buyer-best-solution';
import WinningSolution from './winning-solution';
import SupplierLowestBid from './supplier-lowest-bid';
import BuyerBidList from './buyer-bid-list';
import SupplierBidList from './supplier-bid-list';
import BiddingForm from './bidding-form';
import InvitedSuppliers from './invited-suppliers';
import AuctionInvitation from './auction-invitation';
import MediaQuery from 'react-responsive';
import AuctionLogLink from './auction-log-link';
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';

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
    const fuel = _.get(auction, 'fuel.name');

    const additionInfoDisplay = (auction) => {
      if (auction.additional_information) {
        return auction.additional_information;
      } else {
        return <i>No additional information provided.</i>;
      }
    }

    const auctionLogLinkDisplay = () => {
      if (currentUser.isBuyer && auctionState.status != 'pending' && auctionState.status != 'open') {
        return <AuctionLogLink auction={auction} />;
      } else {
        return false;
      }
    }

    const buyerBidComponents = () => {
      if (auctionState.status == 'open') {
        return (
          <div>
            <BuyerLowestBid auctionPayload={auctionPayload} />
            <BuyerBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else if (auctionState.status == 'decision') {
        return (
          <div>
            <BuyerBestSolution auctionPayload={auctionPayload} selectBid={this.props.selectBid}/>
            <BuyerBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else if (auctionState.status != 'pending') {
        return (
          <div>
            <WinningSolution auctionState={auctionState} />
            <BuyerBestSolution auctionPayload={auctionPayload} selectBid={this.props.selectBid}/>
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
            <SupplierLowestBid auctionPayload={auctionPayload} connection={this.props.connection} />
            <BiddingForm formSubmit={this.props.formSubmit} auction={auction} />
            <SupplierBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else if (auctionState.status != 'pending') {
        return (
          <div>
            <SupplierLowestBid auctionPayload={auctionPayload} />
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
        <MediaQuery query="(min-width: 768px)">
          <AuctionBreadCrumbs auction={auction} />
        </MediaQuery>
        <AuctionHeader auctionPayload={auctionPayload} timeRemaining={this.state.timeRemaining} connection={this.props.connection} />
        <MediaQuery query="(min-width: 768px)">
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
                  <Tabs className="column is-one-third">
                    <div className="tabs is-fullwidth is-medium">
                      <TabList>
                        <Tab>
                          <h2 className="title is-size-5">Auction Details</h2>
                        </Tab>
                        <Tab>
                          <h2 className="title is-size-5">Messages</h2>
                        </Tab>
                      </TabList>
                    </div>
                    <TabPanel>
                      { auctionLogLinkDisplay() }
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
                              <strong>{fuel}</strong> {auction.fuel_quantity} MT
                            </li>
                          </ul>
                        </div>
                        <div className="box__subsection">
                          <h3 className="box__header">Port Information</h3>
                          <ul className="list has-no-bullets">
                            <li>
                              <strong className="is-block">{auction.port.name}</strong>
                              <span className="is-size-7"><strong>ETA</strong> {formatUTCDateTime(auction.eta)} &ndash; <strong>ETD</strong> {formatUTCDateTime(auction.etd)}</span>
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
                    </TabPanel>
                    <TabPanel>
                      <div className = "auction-notification box is-gray-0" >
                        <h3 className="has-text-weight-bold is-flex">
                        <span className="is-inline-block qa-supplier-bid-status-message">Messaging is coming soon!</span>
                        </h3>
                      </div>
                    </TabPanel>
                  </Tabs>
                </div>
              </div>
            </div>
          </section>
        </MediaQuery>
        <MediaQuery query="(max-width: 768px)">
          <section className="auction-page"> {/* Auction details */}
            <div className="container has-padding-left-none has-padding-right-none">
              <Tabs className="auction-content">
                <div className="tabs is-fullwidth is-medium">
                  <TabList>
                    <Tab><h2 className="title is-size-5">Monitor</h2></Tab>
                    <Tab><h2 className="title is-size-5">Details</h2></Tab>
                    <Tab><h2 className="title is-size-5">Messages</h2></Tab>
                  </TabList>
                </div>
                <TabPanel>
                  { currentUser.isBuyer ? buyerBidComponents() : supplierBidComponents() }
                </TabPanel>
                <TabPanel>
                  { auctionLogLinkDisplay() }
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
                          <strong>{fuel}</strong> {auction.fuel_quantity} MT
                        </li>
                      </ul>
                    </div>
                    <div className="box__subsection">
                      <h3 className="box__header">Port Information</h3>
                      <ul className="list has-no-bullets">
                        <li>
                          <strong className="is-block">{auction.port.name}</strong>
                          <span className="is-size-7"><strong>ETA</strong> {formatUTCDateTime(auction.eta)} &ndash; <strong>ETD</strong> {formatUTCDateTime(auction.etd)}</span>
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
                </TabPanel>
                <TabPanel>
                  <div className = "auction-notification box is-gray-0" >
                    <h3 className="has-text-weight-bold is-flex">
                    <span className="is-inline-block qa-supplier-bid-status-message">Messaging is coming soon!</span>
                    </h3>
                  </div>
                </TabPanel>
              </Tabs>
            </div>
          </section>
        </MediaQuery>
      </div>
    );
  }
}
