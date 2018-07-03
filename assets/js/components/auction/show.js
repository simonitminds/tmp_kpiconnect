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
import SupplierWinningBid from './supplier-winning-bid';
import BuyerBidList from './buyer-bid-list';
import SupplierBidList from './supplier-bid-list';
import BiddingForm from './bidding-form';
import InvitedSuppliers from './invited-suppliers';
import AuctionInvitation from './auction-invitation';
import MediaQuery from 'react-responsive';
import AuctionLogLink from './auction-log-link';
import BidStatus from './bid-status';
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';

export default class AuctionShow extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      timeRemaining: timeRemainingCountdown(props.auctionPayload, moment().utc()),
      serverTime: moment().utc()
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

  componentDidUpdate() {
    // For adjusting the auction app body and header
    // portions based on header content
    updateAuctionBodySize();
  }

  tick() {
    let time = moment(ServerDate.now()).utc();
    this.setState({
      timeRemaining: timeRemainingCountdown(this.props.auctionPayload, time),
      serverTime: time
    });
  }

  render() {
    const auctionPayload = this.props.auctionPayload;
    const auctionState = auctionPayload.state;
    const auction = auctionPayload.auction;
    const bidStatusDisplay = () => {
      if (auctionPayload.message) {
        return <BidStatus auctionPayload={auctionPayload} updateBidStatus={this.props.updateBidStatus} />
      }
    };

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

    const portAgentDisplay = () => {
      if (auction.port_agent) {
        return (
          <li>
            <strong className="is-block">Port Agent</strong>
            <span className="qa-port_agent">{auction.port_agent}</span>
          </li>
        );
      } else {
        return <span className="qa-port_agent"></span>;
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
            <BuyerBestSolution auctionPayload={auctionPayload} acceptBid={this.props.acceptBid}/>
            <BuyerBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else if (auctionState.status != 'pending') {
        return (
          <div>
            <WinningSolution auctionPayload={auctionPayload} />
            <BuyerBestSolution auctionPayload={auctionPayload} acceptBid={this.props.acceptBid}/>
            <BuyerBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else {
        return (
          <div className = "auction-notification box is-gray-0" >
            <h3 className="has-text-weight-bold">
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
            {bidStatusDisplay()}
            <SupplierLowestBid auctionPayload={auctionPayload} connection={this.props.connection} />
            <BiddingForm formSubmit={this.props.formSubmit} auctionPayload={auctionPayload} />
            <SupplierBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else if (auctionState.status == 'decision') {
        return (
          <div>
            <SupplierLowestBid auctionPayload={auctionPayload} />
            <SupplierBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else if (auctionState.status != 'pending') {
        return (
          <div>
            {bidStatusDisplay()}
            <SupplierWinningBid auctionPayload={auctionPayload} />
            <SupplierBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else {
        return (
          <div>
            <div className = "auction-notification box is-gray-0" >
              <h3 className="has-text-weight-bold is-flex">
                <span className="is-inline-block qa-supplier-bid-status-message">The auction has not started yet</span>
              </h3>
              <BiddingForm formSubmit={this.props.formSubmit} auctionPayload={auctionPayload} />
            </div>
            <SupplierBidList auctionPayload={auctionPayload} />
          </div>
        )
      }
    }

    return (
      <div className="auction-app">
        <MediaQuery query="(min-width: 769px)">
          <AuctionBreadCrumbs auction={auction} />
        </MediaQuery>
        <AuctionHeader auctionPayload={auctionPayload} timeRemaining={this.state.timeRemaining} connection={this.props.connection} serverTime={this.state.serverTime} />
        <MediaQuery query="(min-width: 769px)">
          <div className="auction-app__body">
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
                          {/* <Tab>
                            <h2 className="title is-size-5">Messages</h2>
                          </Tab> */}
                        </TabList>
                      </div>
                      <TabPanel>
                        { auctionLogLinkDisplay() }
                        { currentUser.isBuyer ? "" : <AuctionInvitation auction={auction} /> }
                        { currentUser.isBuyer ? <InvitedSuppliers auction={auction} /> : "" }

                        <div className="box has-margin-bottom-md">
                          <div className="box__subsection">
                            <h3 className="box__header">Buyer Information
                              <div className="field is-inline-block is-pulled-right">
                                { currentUser.isBuyer && auctionState.status != 'open' && auctionState.status != 'decision' ?
                                  <a className="button is-primary is-small has-family-copy is-capitalized" href={`/auctions/${auction.id}/edit`}>Edit</a>
                                  :
                                  <div> </div>
                                }
                              </div>
                            </h3>
                            <ul className="list has-no-bullets">
                              <li className="is-not-flex">
                                <strong className="is-block">Organization</strong> {auction.buyer.name}
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
                              <li className="is-not-flex">
                                <strong className="is-inline">{fuel}</strong> {auction.fuel_quantity} MT
                              </li>
                            </ul>
                          </div>
                          <div className="box__subsection">
                            <h3 className="box__header">Port Information</h3>
                            <ul className="list has-no-bullets">
                              <li className="is-not-flex">
                                <strong className="is-block">{auction.port.name}</strong>
                                <span className="is-block"><strong>ETA</strong> {formatUTCDateTime(auction.eta)}</span>
                                <span className="is-block"><strong>ETD</strong> {formatUTCDateTime(auction.etd)}</span>
                              </li>
                              { portAgentDisplay() }
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
                      {/* <TabPanel>
                        <div className = "auction-notification box is-gray-0" >
                          <h3 className="has-text-weight-bold is-flex">
                          <span className="is-inline-block qa-supplier-bid-status-message">Messaging is coming soon!</span>
                          </h3>
                        </div>
                      </TabPanel> */}
                    </Tabs>
                  </div>
                </div>
              </div>
            </section>
          </div>
        </MediaQuery>
        <MediaQuery query="(max-width: 768px)">
          <div className="auction-app__body">
            <section className="auction-page"> {/* Auction details */}
              <div className="container has-padding-left-none has-padding-right-none">
                <Tabs className="auction-content">
                  <div className="tabs is-fullwidth is-medium">
                    <TabList>
                      <Tab><h2 className="title is-size-5">Monitor</h2></Tab>
                      <Tab><h2 className="title is-size-5">Details</h2></Tab>
                      {/* <Tab><h2 className="title is-size-5">Messages</h2></Tab> */}
                    </TabList>
                  </div>
                  <TabPanel>
                    { currentUser.isBuyer ? buyerBidComponents() : supplierBidComponents() }
                  </TabPanel>
                  <TabPanel>
                    { auctionLogLinkDisplay() }
                    {/* { currentUser.isBuyer ? "" : <AuctionInvitation auction={auction} /> } */}
                    { currentUser.isBuyer ? <InvitedSuppliers auction={auction} /> : "" }
                    <div className="box has-margin-bottom-md">
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
                          <li className="is-not-flex">
                            <strong className="is-block">Organization</strong> {auction.buyer.name}
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
                          <li className="is-not-flex">
                            <strong className="is-inline">{fuel}</strong> {auction.fuel_quantity} MT
                          </li>
                        </ul>
                      </div>
                      <div className="box__subsection">
                        <h3 className="box__header">Port Information</h3>
                        <ul className="list has-no-bullets">
                          <li className="is-not-flex">
                            <strong className="is-block">{auction.port.name}</strong>
                            <span className="is-block"><strong>ETA</strong> {formatUTCDateTime(auction.eta)}</span>
                            <span className="is-block"><strong>ETD</strong> {formatUTCDateTime(auction.etd)}</span>
                          </li>
                          { portAgentDisplay() }
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
                  {/* <TabPanel>
                    <div className = "auction-notification box is-gray-0" >
                      <h3 className="has-text-weight-bold is-flex">
                      <span className="is-inline-block qa-supplier-bid-status-message">Messaging is coming soon!</span>
                      </h3>
                    </div>
                  </TabPanel> */}
                </Tabs>
              </div>
            </section>
          </div>
        </MediaQuery>
      </div>
    );
  }
}

function updateAuctionBodySize() {
  const auctionHeaderSection = document.querySelector('.auction-app__header'),
        auctionHeaderOffsetHeight = auctionHeaderSection ? auctionHeaderSection.offsetHeight : 0,
        collapsingBidBox = document.querySelector('.collapsing-auction-bidding'),
        collapsingBidHeight = collapsingBidBox ? collapsingBidBox.offsetHeight : 0,
        auctionTabContentHeight = `calc(100vh - ${auctionHeaderOffsetHeight + 37 + 48}px)`,
        auctionTabBidContentHeight = collapsingBidHeight ? `calc(100vh - ${auctionHeaderOffsetHeight + 37 + 48 + collapsingBidHeight}px)` : `calc(100vh - ${auctionHeaderOffsetHeight + 37 + 48}px)`,
        auctionTabWithAlertHeight = `calc(100vh - ${auctionHeaderOffsetHeight + 37 + 48 + 42}px)`,
        auctionTabContent = document.querySelector('.react-tabs__tab-panel--selected'),
        alertPresence = document.querySelector('.alert:not(:empty)'),
        bidPresence = document.querySelector('.auction-bidding');


  if(alertPresence) {
    auctionTabContent.style.height = auctionTabWithAlertHeight;
  } else {
    auctionTabContent.style.height = auctionTabContentHeight;
  }

  if(bidPresence && window.screen.width <= 768) {
    auctionTabContent.style.height = auctionTabBidContentHeight;
  }
}
