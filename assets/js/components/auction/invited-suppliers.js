import React from 'react';
import _ from 'lodash';
import CollapsingBargeList from './collapsing-barge-list';
import CollapsingBarge from './collapsing-barge';

const InvitedSuppliers = ({auctionPayload, approveBargeForm, rejectBargeForm}) => {
  const suppliers = _.get(auctionPayload, 'auction.suppliers');
  const participations = _.get(auctionPayload, 'participations');
  const auctionBarges = _.get(auctionPayload, 'submitted_barges');

  const auctionBargesBySupplier = auctionBarges.reduce((acc, barge) => {
    acc[barge.supplier_id] = acc[barge.supplier_id] || [];
    acc[barge.supplier_id].push(barge);
    return acc;
  }, {});

  // const supplierBargeCount = auctionBargesBySupplier[supplier.id].length;

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
                key={barge.id}
              >
              </CollapsingBarge>
            );
          })
        }
      </div>
    );
  };

  const renderSupplierParticipation = (status, supplier) => {
    if (status == "yes") {
      return <span className={`icon has-text-success has-margin-right-sm qa-auction-rsvp-response-${supplier.id}`}><i className="fas fa-check-circle"></i></span>;
    } else if (status == "no") {
      return <span className={`icon has-text-danger has-margin-right-sm qa-auction-rsvp-response-${supplier.id}`}><i className="fas fa-times-circle"></i></span>;
    } else if (status == "maybe"){
        return <span className={`icon has-text-danger has-margin-right-sm qa-auction-rsvp-response-${supplier.id}`}><i className="fas fa-adjust-circle"></i></span>;
    } else {
      return <span className={`icon has-text-gray-3 has-margin-right-sm qa-auction-rsvp-response-${supplier.id}`}><i className="fas fa-question-circle"></i></span>;
    }
  }

  return(
    <div className="box">
      <h3 className="box__header">Invited Suppliers</h3>
      <ul className="supplier-list list has-no-bullets qa-auction-suppliers">
        { _.map(suppliers, (supplier) => {
          const bargeList = auctionBargesBySupplier[supplier.id] || [];
          const bargeCount = bargeList.length;
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
              </div>
            );
          })
        }
      </ul>
    </div>
  );
};

export default InvitedSuppliers;
