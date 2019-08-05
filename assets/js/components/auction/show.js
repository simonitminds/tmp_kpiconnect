import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime, timeRemainingCountdown } from '../../utilities';
import moment from 'moment';
import ServerDate from '../../serverdate';
import AuctionBreadCrumbs from './auction-bread-crumbs';
import MediaQuery from 'react-responsive';
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';
import { componentsForAuction } from './common';

export default class AuctionShow extends React.Component {
  constructor(props) {
    super(props);
  }

  componentDidUpdate() {
    // For adjusting the auction app body and header
    // portions based on header content in mobile
    updateAuctionBodySize();
  }

  render() {
    const {
      auctionPayload,
      companyProfile,
      inviteObserver,
      submitBargeForm,
      unsubmitBargeForm,
      approveBargeForm,
      rejectBargeForm,
      updateBidStatus,
      acceptSolution,
      currentUserCompanyId,
      revokeSupplierBid,
      formSubmit,
      removeCommentFromSolution,
      addCommentToSolution,
      connection
    } = this.props;
    const {auction, status} = auctionPayload;
    const isAdmin = window.isAdmin;

    const currentUser = {
      isBuyer: parseInt(this.props.currentUserCompanyId) === auction.buyer_id,
      isAdmin: window.isAdmin && !window.isImpersonating
    };

    const auctionType = _.get(auction, 'type');
    const { Header, BuyerBody, SupplierBody, BuyerSidebar, SupplierSidebar } = componentsForAuction(auctionType);

    return (
      <div className="auction-app">
        <MediaQuery query="(min-width: 769px)">
          <AuctionBreadCrumbs auction={auction} />
        </MediaQuery>
        <Header auctionPayload={auctionPayload} connection={connection} />
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
                            <h2 className="title"><a className="has-text-left">Auction Monitor</a></h2>
                          </li>
                        </ul>
                      </div>
                    { (currentUser.isBuyer || currentUser.isAdmin)
                      ? <BuyerBody
                          auctionPayload={auctionPayload}
                          acceptSolution={acceptSolution}
                          currentUser={currentUser}
                        />
                      : <SupplierBody
                          auctionPayload={auctionPayload}
                          currentUser={currentUser}
                          connection={connection}
                          currentUserCompanyId={currentUserCompanyId}
                          updateBidStatus={updateBidStatus}
                          revokeSupplierBid={revokeSupplierBid}
                          formSubmit={formSubmit}
                          addCommentToSolution={addCommentToSolution}
                          removeCommentFromSolution={removeCommentFromSolution}
                        />
                    }
                    </div>
                    <Tabs className="column is-one-third">
                      <div className="tabs is-fullwidth is-medium">
                        <TabList>
                          <Tab>
                            <h2 className="title">Auction Details</h2>
                          </Tab>
                        </TabList>
                      </div>
                      <TabPanel>
                        { currentUser.isBuyer || currentUser.isAdmin
                          ? <BuyerSidebar
                              auctionPayload={auctionPayload}
                              approveBargeForm={approveBargeForm}
                              rejectBargeForm={rejectBargeForm}
                              inviteObserver={inviteObserver}
                            />
                          : <SupplierSidebar
                              auctionPayload={auctionPayload}
                              submitBargeForm={submitBargeForm}
                              unsubmitBargeForm={unsubmitBargeForm}
                              rejectBargeForm={rejectBargeForm}
                              currentUserCompanyId={currentUserCompanyId}
                              companyProfile={companyProfile}
                            />
                        }
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
                      <Tab><h2 className="title">Monitor</h2></Tab>
                      <Tab><h2 className="title">Details</h2></Tab>
                    </TabList>
                  </div>
                  <TabPanel>
                    { (currentUser.isBuyer || currentUser.isAdmin)
                      ? <BuyerBody
                          auctionPayload={auctionPayload}
                          acceptSolution={acceptSolution}
                          currentUser={currentUser}
                        />
                      : <SupplierBody
                          auctionPayload={auctionPayload}
                          currentUser={currentUser}
                          connection={connection}
                          currentUserCompanyId={currentUserCompanyId}
                          updateBidStatus={updateBidStatus}
                          revokeSupplierBid={revokeSupplierBid}
                          formSubmit={formSubmit}
                          addCommentToSolution={addCommentToSolution}
                          removeCommentFromSolution={removeCommentFromSolution}
                        />
                    }
                  </TabPanel>
                  <TabPanel>
                    { currentUser.isBuyer || currentUser.isAdmin
                      ? <BuyerSidebar
                          auctionPayload={auctionPayload}
                          approveBargeForm={approveBargeForm}
                          rejectBargeForm={rejectBargeForm}
                        />
                      : <SupplierSidebar
                          auctionPayload={auctionPayload}
                          submitBargeForm={submitBargeForm}
                          unsubmitBargeForm={unsubmitBargeForm}
                          currentUserCompanyId={currentUserCompanyId}
                          companyProfile={companyProfile}
                        />
                    }
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
