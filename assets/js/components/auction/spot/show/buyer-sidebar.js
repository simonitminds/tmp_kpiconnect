import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../../../utilities';
import moment from 'moment';
import LogLink from './log-link';
import SidebarDetails from './sidebar-details';
import InvitedSuppliers from '../../common/invited-suppliers';
import InvitedObservers from '../../common/show/observers/invited-observers';

const BuyerSidebar = (props) => {
  const {
    auctionPayload,
    addCOQ,
    deleteCOQ,
    approveBargeForm,
    rejectBargeForm,
    inviteObserver,
    uninviteObserver
  } = props;

  const { auction, status } = auctionPayload;
  const vesselFuels = _.get(auction, 'auction_vessel_fuels');
  const isAdmin = window.isAdmin;
  const isImpersonating = window.isImpersonating;
  const isObserver = window.isObserver;
  const isEditable = status != 'open' && status != 'decision';

  return (
    <React.Fragment>
      { !isObserver &&
        <div className="box">
          <h3 className="box__header box__header--bordered has-margin-bottom-md">Auction Reports</h3>
          { (isAdmin && (status == 'closed' || status == 'expired')) &&
            <a className="button is-info has-family-copy has-margin-right-sm qa-admin-fixtures-link" href={`/admin/auctions/${auctionPayload.auction.id}/fixtures`}>View Fixtures</a>
          }
          { (isAdmin || (status != 'pending')) &&
            <LogLink auction={auction} />
          }
        </div>
      }
      { isAdmin && !isImpersonating && status != 'closed' && status != 'canceled' && status != 'expired' &&
        <InvitedObservers
          auctionPayload={auctionPayload}
          inviteObserver={inviteObserver}
          uninviteObserver={uninviteObserver}
        />
      }
      <InvitedSuppliers
        auctionPayload={auctionPayload}
        addCOQ={addCOQ}
        deleteCOQ={deleteCOQ}
        approveBargeForm={approveBargeForm}
        rejectBargeForm={rejectBargeForm}
      />
      <SidebarDetails auctionPayload={auctionPayload} isEditable={isEditable} />
    </React.Fragment>
  );
};

export default BuyerSidebar;
