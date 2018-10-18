import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SolutionComment from './solution-comment';
import SolutionDisplay from './solution-display';
import InputField from '../input-field';

const OtherSolutions = ({auctionPayload, solutions, acceptSolution}) => {
    if (solutions.length > 1) {
    return(
      <div className="auction-solution__container qa-auction-other-solutions">
        <div className="box">
          <div className="box__subsection has-padding-bottom-none">
            <h3 className="box__header box__header--bordered has-margin-bottom-md">Other Solutions</h3>
            { _.map(solutions, (solution) => {
                return (
                  <SolutionDisplay auctionPayload={auctionPayload} solution={solution} acceptSolution={acceptSolution} best={false} className="qa-auction-other-solution" />
                );
              })
            }
          </div>
        </div>
      </div>
      )
    }
  else {
    return("");
  }
};

export default OtherSolutions;
