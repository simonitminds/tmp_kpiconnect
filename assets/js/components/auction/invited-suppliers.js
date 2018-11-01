import React from 'react';
import _ from 'lodash';
import CollapsingBargeList from './collapsing-barge-list';
import CollapsingBarge from './collapsing-barge';

const InvitedSuppliers = ({auctionPayload, approveBargeForm, rejectBargeForm}) => {
  const suppliers = _.get(auctionPayload, 'auction.suppliers');
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

            return (

              <div key={supplier.id} className={`qa-auction-supplier-${supplier.id}`}>
                <li className="supplier-list__supplier">
                  <span className="icon has-text-success has-margin-right-sm"><i className="fas fa-check-circle"></i></span>
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
