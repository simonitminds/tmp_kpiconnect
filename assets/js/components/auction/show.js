import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime, timeRemainingCountdown} from '../../utilities';
import moment from 'moment';
import ServerDate from '../../serverdate';
import AuctionBreadCrumbs from './auction-bread-crumbs';
import AuctionHeader from './auction-header';
import BuyerBestSolution from './buyer-best-solution';
import OtherSolutions from './other-solutions';
import WinningSolution from './winning-solution';
import SupplierBestSolution from './supplier-best-solution';
import BuyerBidList from './buyer-bid-list';
import SupplierBidList from './supplier-bid-list';
import SupplierBidStatus from './supplier-bid-status';
import BiddingForm from './bidding-form';
import InvitedSuppliers from './invited-suppliers';
import AuctionInvitation from './auction-invitation';
import BargeSubmission from './barge-submission';
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
    // portions based on header content in mobile
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
    const companyProfile = this.props.companyProfile;
    const {auction, status} = auctionPayload;
    const isAdmin = window.isAdmin;

    const bidStatusDisplay = () => {
      if (auctionPayload.message) {
        return <BidStatus auctionPayload={auctionPayload} updateBidStatus={this.props.updateBidStatus} />
      }
    };

    const currentUser = {
      isBuyer: parseInt(this.props.currentUserCompanyId) === auction.buyer_id,
      isAdmin: window.isAdmin && !window.isImpersonating
    };
    const fuels = _.get(auction, 'fuels');
    const vessels = _.get(auction, 'vessels');

    const additionInfoDisplay = (auction) => {
      if (auction.additional_information) {
        return auction.additional_information;
      } else {
        return <i>No additional information provided.</i>;
      }
    }

    const auctionLogLinkDisplay = () => {
      if ((currentUser.isBuyer && auctionPayload.status != 'pending' && auctionPayload.status != 'open') || isAdmin) {
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
      const otherSolutions = _.get(auctionPayload, 'solutions.other_solutions');

      if (auctionPayload.status == 'open') {
        return (
          <div>
            <BuyerBestSolution auctionPayload={auctionPayload} />
            <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} />
            <BuyerBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else if (auctionPayload.status == 'decision') {
        return (
          <div>
            {currentUser.isAdmin ?
             <div>
              <BuyerBestSolution auctionPayload={auctionPayload} />
              <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} />
             </div>
            :
             <div>
               <BuyerBestSolution auctionPayload={auctionPayload} acceptSolution={this.props.acceptSolution} />
               <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} acceptSolution={this.props.acceptSolution} />
             </div>
            }
            <BuyerBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else if (auctionPayload.status != 'pending') {
        return (
          <div>
            <WinningSolution auctionPayload={auctionPayload} />
            {currentUser.isAdmin ?
            <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} />
            :
            <OtherSolutions auctionPayload={auctionPayload} solutions={otherSolutions} acceptSolution={this.props.acceptSolution} />
            }
            <BuyerBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else {
        return (
          <div className="auction-notification box is-gray-0" >
            <h3 className="has-text-weight-bold">
            <span className="is-inline-block qa-supplier-bid-status-message">The auction has not started yet</span>
            </h3>
          </div>
        )
      }
    }

    const supplierBidComponents = () => {
      if (auctionPayload.status == 'open') {
        return (
          <div>
            {bidStatusDisplay()}
            <SupplierBestSolution auctionPayload={auctionPayload} connection={this.props.connection} revokeBid={this.props.revokeSupplierBid} supplierId={this.props.currentUserCompanyId} />
            <BiddingForm formSubmit={this.props.formSubmit} revokeBid={this.props.revokeSupplierBid} auctionPayload={auctionPayload} />
            <SupplierBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else if (auctionPayload.status == 'decision') {
        return (
          <div>
            <SupplierBestSolution auctionPayload={auctionPayload} supplierId={this.props.currentUserCompanyId} />
            <SupplierBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else if (auctionPayload.status != 'pending') {
        return (
          <div>
            {bidStatusDisplay()}
            <SupplierBidStatus auctionPayload={auctionPayload} connection={this.props.connection} supplierId={this.props.currentUserCompanyId} />
            <WinningSolution auctionPayload={auctionPayload} />
            <SupplierBidList auctionPayload={auctionPayload} />
          </div>
        )
      } else {
        return (
          <div>
            <div className="auction-notification box is-gray-0" >
              <h3 className="has-text-weight-bold is-flex">
                <span className="is-inline-block qa-supplier-bid-status-message">The auction has not started yet</span>
              </h3>
            </div>
            <SupplierBestSolution auctionPayload={auctionPayload} connection={this.props.connection} supplierId={this.props.currentUserCompanyId} />
            <BiddingForm formSubmit={this.props.formSubmit} auctionPayload={auctionPayload} />
            <SupplierBidList auctionPayload={auctionPayload} />
          </div>
        )
      }
    }

    const fuelRequirementDisplay = (fuels) => {
      if(fuels.length == 0) {
        return (
          <i>No fuels have been specified for this auction</i>
        );
      }

      return _.map(fuels, (fuel) => {
        return (
          <li className={`is-not-flex qa-auction-fuel-${fuel.id}`} key={fuel.id}>
            <strong className="is-inline">{fuel.name}</strong>
            <div className="qa-auction_vessel_fuels-quantities">
            { _.map(vessels, (vessel) => {
                let vesselFuel = _.find(auction.auction_vessel_fuels, {'fuel_id': fuel.id, 'vessel_id': vessel.id});
                if(vesselFuel) {
                  return(
                    <div key={vessel.id}>
                      { vesselFuel.quantity } MT to <span className="is-inline">{vessel.name}</span>
                    </div>
                  );
                }
              })
            }
            </div>
          </li>
        );
      });
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
                    { (currentUser.isBuyer || currentUser.isAdmin) ? buyerBidComponents() : supplierBidComponents() }
                    </div>
                    <Tabs className="column is-one-third">
                      <div className="tabs is-fullwidth is-medium">
                        <TabList>
                          <Tab>
                            <h2 className="title is-size-5">Auction Details</h2>
                          </Tab>
                        </TabList>
                      </div>
                      <TabPanel>
                        { auctionLogLinkDisplay() }
                        { (!currentUser.isBuyer && !currentUser.isAdmin) && (status == 'pending' || status == 'open') &&
                          <AuctionInvitation auctionPayload={auctionPayload} supplierId={this.props.currentUserCompanyId}/>
                        }
                        { currentUser.isBuyer ?
                          <InvitedSuppliers
                            auctionPayload={auctionPayload}
                            approveBargeForm={this.props.approveBargeForm}
                            rejectBargeForm={this.props.rejectBargeForm}
                          /> :
                          <BargeSubmission
                            submitBargeForm={this.props.submitBargeForm}
                            unsubmitBargeForm={this.props.unsubmitBargeForm}
                            auctionPayload={auctionPayload}
                            companyBarges={companyProfile.companyBarges}
                            supplierId={this.props.currentUserCompanyId}
                          />
                        }
                        <div className="box has-margin-bottom-md">
                          <div className="box__subsection">
                            <h3 className="box__header">Buyer Information
                              <div className="field is-inline-block is-pulled-right">
                              { (currentUser.isBuyer || currentUser.isAdmin) && auctionPayload.status != 'open' && auctionPayload.status != 'decision' ?
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
                              {fuelRequirementDisplay(fuels)}
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
                              { auction.anonymous_bidding &&
                                <li className="qa-auction-anonymous_bidding">
                                  "Supplier bids on this auction are placed anonymously."
                                </li>
                              }
                            </ul>
                          </div>
                        </div>
                      </TabPanel>
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
                <Tabs className="auction-content auction-content--mobile">
                  <div className="tabs is-fullwidth is-medium">
                    <TabList>
                      <Tab><h2 className="title is-size-5">Monitor</h2></Tab>
                      <Tab><h2 className="title is-size-5">Details</h2></Tab>
                    </TabList>
                  </div>
                  <TabPanel>
                    { (currentUser.isBuyer || currentUser.isAdmin) ? buyerBidComponents() : supplierBidComponents() }
                  </TabPanel>
                  <TabPanel>
                    { auctionLogLinkDisplay() }
                    { (currentUser.isBuyer || currentUser.isAdmin) ? "" : <AuctionInvitation auctionPayload={auctionPayload} supplierId={this.props.currentUserCompanyId}/> }
                    { (currentUser.isBuyer || currentUser.isAdmin) ?
                      <InvitedSuppliers
                        auctionPayload={auctionPayload}
                        approveBargeForm={this.props.approveBargeForm}
                        rejectBargeForm={this.props.rejectBargeForm}
                      /> :
                      <BargeSubmission
                        submitBargeForm={this.props.submitBargeForm}
                        unsubmitBargeForm={this.props.unsubmitBargeForm}
                        auctionPayload={auctionPayload}
                        companyBarges={companyProfile.companyBarges}
                        supplierId={this.props.currentUserCompanyId}
                      />
                    }
                    <div className="box has-margin-bottom-md">
                      <div className="box__subsection">
                        <h3 className="box__header">Buyer Information
                          <div className="field is-inline-block is-pulled-right">
                            { (currentUser.isBuyer || currentUser.isAdmin) ?
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
                          {fuelRequirementDisplay(fuels)}
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
        auctionTabContentHeight = `calc(100vh - ${auctionHeaderOffsetHeight + 37 + 20}px)`,
        auctionTabBidContentHeight = collapsingBidHeight ? `calc(100vh - ${auctionHeaderOffsetHeight + 37 + 20 + collapsingBidHeight}px)` : `calc(100vh - ${auctionHeaderOffsetHeight + 37 + 20}px)`,
        auctionTabWithAlertHeight = `calc(100vh - ${auctionHeaderOffsetHeight + 37 + 48 + 42}px)`,
        auctionTabContent = document.querySelector('.auction-content--mobile .react-tabs__tab-panel--selected'),
        alertPresence = document.querySelector('.alert:not(:empty)'),
        bidPresence = document.querySelector('.auction-bidding');

  if(auctionTabContent != null) {
    if(alertPresence) {
      auctionTabContent.style.height = auctionTabWithAlertHeight;
    } else {
      auctionTabContent.style.height = auctionTabContentHeight;
    }

    if(bidPresence) {
      auctionTabContent.style.height = auctionTabBidContentHeight;
    }
  }
}
