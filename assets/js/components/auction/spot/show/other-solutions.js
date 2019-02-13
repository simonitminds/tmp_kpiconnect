import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../../../utilities';
import CustomSolutionDisplay from '../../common/show/custom-solution-display';
import SolutionDisplay from '../../common/show/solution-display';
import InputField from '../../../input-field';

const OtherSolutions = ({auctionPayload, solutions, showCustom, acceptSolution}) => {
  if (solutions.length > 0) {
    return(
      <div className="auction-solution__container qa-auction-other-solutions">
        <div className="box">
          <div className="box__subsection has-padding-bottom-none">
            <h3 className="box__header box__header--bordered has-margin-bottom-md">Other Solutions</h3>
            { _.map(solutions, (solution, index) => {
                return (
                  <SolutionDisplay key={index} auctionPayload={auctionPayload} solution={solution} acceptSolution={acceptSolution} best={false} className="qa-auction-other-solution" />
                );
              })
            }
            { showCustom &&
              <CustomSolutionDisplay auctionPayload={auctionPayload} acceptSolution={acceptSolution} className="qa-auction-solution-custom" />
            }
          </div>
        </div>
      </div>
    )
  } else {
    return "";
  }
};

export default OtherSolutions;
