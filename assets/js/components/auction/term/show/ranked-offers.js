import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../../../utilities';
import SolutionDisplay from './solution-display';
import InputField from '../../../input-field';

const RankedOffers = ({auctionPayload, solutions, acceptSolution}) => {
  const { status } = auctionPayload;

  if ( status != 'pending' && solutions.length > 0) {
    return(
      <div className="auction-solution__container qa-auction-other-solutions">
        <div className="box">
          <div className="box__subsection has-padding-bottom-none">
            <h3 className="box__header box__header--bordered has-margin-bottom-md">Ranked Offers</h3>
            { _.map(solutions, (solution, index) => {
                return <SolutionDisplay
                    key={index}
                    auctionPayload={auctionPayload}
                    solution={solution}
                    acceptSolution={acceptSolution}
                    best={false}
                    className="qa-auction-other-solution"
                  />;
              })
            }
          </div>
        </div>
      </div>
    )
  } else if (status == 'pending') {
    return(
      <div className="auction-solution__container qa-auction-other-solutions">
        <div className="box">
          <div className="box__subsection has-padding-bottom-none">
            <h3 className="box__header box__header--bordered has-margin-bottom-md">Ranked Offers</h3>
            <div className="auction-table-placeholder">
              <i>Any bids placed during the pending period will display upon auction start</i>
            </div>
          </div>
        </div>
      </div>
    )
  } else {
    return (
      <div className="auction-solution__container qa-auction-other-solutions">
        <div className="box">
          <div className="box__subsection has-padding-bottom-none">
            <h3 className="box__header box__header--bordered has-margin-bottom-md">Ranked Offers</h3>
            <div className="auction-table-placeholder">
              <i>No bids have been placed on this auction</i>
            </div>
          </div>
        </div>
      </div>
    );
  }
};

export default RankedOffers;
