import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';
import CollapsingBargeList from './show/collapsing-barge-list';
import CollapsingBarge from './show/collapsing-barge';
import COQSubmission from './show/coq-submission';
import ViewCOQ from './show/view-coq';

function rsvpSortingRank(response) {
  switch(response) {
    case "yes": return 0;
    case "maybe": return 1;
    default: return 2;
    case "no": return 3;
  }
}

const InvitedSuppliers = ({auctionPayload, approveBargeForm, rejectBargeForm, addCOQ, deleteCOQ}) => {
  const auctionState = _.get(auctionPayload, 'status');
  const participations = _.get(auctionPayload, 'participations');
  const auctionBarges = _.get(auctionPayload, 'submitted_barges');
  const coqList = _.get(auctionPayload, 'auction.auction_supplier_coqs');
  const auction = _.get(auctionPayload, 'auction');
  let fuels = _.get(auction, "auction_vessel_fuels", null);
  if (fuels) {
    fuels = _.map(fuels, "fuel");
  } else {
    fuels = [auction.fuel];
  }
  const rsvpSortingOrder = ["yes", "maybe", null, "no"];
  const suppliers = _.chain(auctionPayload)
    .get('auction.suppliers')
    .sortBy((supplier) => rsvpSortingRank(participations[supplier.id]))
    .value();

  const auctionBargesBySupplier = auctionBarges.reduce((acc, barge) => {
    acc[barge.supplier_id] = acc[barge.supplier_id] || [];
    acc[barge.supplier_id].push(barge);
    return acc;
  }, {});

  const bargesForSupplier = (supplier) => {
    const auctionBarges = auctionBargesBySupplier[supplier.id] || [];

    return (
      <div className={`supplier__barges qa-auction-supplier-${supplier.id}-barges`}>
        { auctionBarges.map((auctionBarge) => {
            const barge = auctionBarge.barge;
            return (
              <CollapsingBarge
                trigger={ `${barge.name} (${barge.imo_number})` }
                classParentString="collapsing-barge__barge"
                easing="ease"
                open={false}
                approveBargeForm={approveBargeForm}
                rejectBargeForm={rejectBargeForm}
                auction={auctionPayload.auction}
                barge={barge}
                supplierId={auctionBarge.supplier_id}
                bargeStatus={auctionBarge.approval_status}
                isBuyer={true}
                auctionState={auctionState}
                key={barge.id}
              >
              </CollapsingBarge>
            );
          })
        }
      </div>
    );
  };

  const renderCOQs = (supplierCOQs, supplierId) => {
    if (window.isAdmin && !window.isImpersonating) {
      return (
        <div>
          {
            fuels.map((fuel) => {
              const supplierCOQ = _.find(supplierCOQs, { 'fuel_id': fuel.id, 'supplier_id': parseInt(supplierId) });
              return (
                <div key={`${supplierId}-${fuel.id}`}>
                  <COQSubmission
                    auctionPayload={auctionPayload}
                    addCOQ={addCOQ}
                    deleteCOQ={deleteCOQ}
                    fuel={fuel}
                    supplierId={supplierId}
                    supplierCOQ={supplierCOQ}
                    delivered={false}
                  />
                </div>
              )
            })
          }
        </div>
      );
    } else {
      return (
        <div>
          {
            supplierCOQs.map((supplierCOQ) => {
              const fuelId = _.get(supplierCOQ, 'fuel_id');
              const fuel = _.chain(fuels).filter(['id', fuelId]).first().value();
              return (
                <div className="collapsing-barge__barge" key={fuelId}>
                  <div className="container is-fullhd">
                    <ViewCOQ supplierCOQ={supplierCOQ} allowedToDelete={false} fuel={fuel}/>
                  </div>
                </div>
              );
            })
          }
        </div>
      );
    }
  };

  const renderSupplierParticipation = (status, supplier) => {
    if (status == "yes") {
      return <span className={`icon has-text-success has-margin-right-sm qa-auction-rsvp-response-${supplier.id}`}><FontAwesomeIcon icon="check-circle" /></span>;
    } else if (status == "maybe"){
        return <span className={`icon has-text-warning has-margin-right-sm qa-auction-rsvp-response-${supplier.id}`}><FontAwesomeIcon icon="adjust" /></span>;
    } else if (status == "no") {
      return <span className={`icon has-text-danger has-margin-right-sm qa-auction-rsvp-response-${supplier.id}`}><FontAwesomeIcon icon="times-circle" /></span>;
    } else {
      return <span className={`icon has-text-gray-3 has-margin-right-sm qa-auction-rsvp-response-${supplier.id}`}><FontAwesomeIcon icon="question-circle" /></span>;
    }
  }

  return(
    <div className="box">
      <h3 className="box__header">Invited Suppliers</h3>
      <ul className="supplier-list list has-no-bullets qa-auction-suppliers">
        { _.map(suppliers, (supplier) => {
          const bargeList = auctionBargesBySupplier[supplier.id] || [];
          const bargeCount = bargeList.length;
          const supplierCOQs = _.filter(coqList, {'supplier_id': supplier.id, 'delivered': false});
          const supplierCOQsCount = supplierCOQs.length;
          const hasPendingBarges = bargeList.some((barge) => {
            return barge.approval_status == 'PENDING'
          })
          const supplierParticipationStatus = _.get(participations, supplier.id);

            return (

              <div key={supplier.id} className={`qa-auction-supplier-${supplier.id}`}>
                <li className="supplier-list__supplier">
                { renderSupplierParticipation(supplierParticipationStatus, supplier) }
                  <span className={`qa-auction-supplier-${supplier.id}-name`}>{supplier.name}</span>
                </li>
                { bargeCount != 0 &&
                  <CollapsingBargeList
                    trigger="Barges"
                    open={hasPendingBarges && true || false}
                    pendingBargeFlag = {hasPendingBarges}
                    triggerClassString="collapsible-barge-list__container__trigger"
                    classParentString="qa-open-barges-list collapsing-barge-list__container"
                    contentChildCount={bargeCount}
                    >
                    { bargesForSupplier(supplier) }
                  </CollapsingBargeList>
                }
                { ((window.isAdmin && !window.isImpersonating) || supplierCOQsCount != 0) &&
                  <CollapsingBargeList
                    trigger="COQ"
                    open={supplierCOQsCount != 0}
                    pendingBargeFlag = {false}
                    triggerClassString="collapsible-barge-list__container__trigger"
                    classParentString="qa-open-barges-list collapsing-barge-list__container"
                    contentChildCount={supplierCOQsCount}
                    >
                    { renderCOQs(supplierCOQs, supplier.id) }
                  </CollapsingBargeList>
                }
              </div>
            );
          })
        }
      </ul>
    </div>
  );
};

export default InvitedSuppliers;
