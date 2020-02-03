import React from 'react';
import _ from 'lodash';
import ViewCOQ from './view-coq';

class COQSubmission extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      uploading: false
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.auctionPayload !== prevProps.auctionPayload) {
      this.setState({
        uploading: false
      })
    }
  }

  submitForm(ev) {
    ev.preventDefault
    this.setState({ uploading: true });
    const coq = ev.target.files[0];
    const { addCOQ, auctionPayload, fuel, supplierId } = this.props;
    const { auction } = auctionPayload;
    addCOQ(auction.id, supplierId, fuel.id, coq);
  }

  render() {
    const { auctionPayload, deleteCOQ, fuel, supplierCOQ } = this.props;
    const auction = _.get(auctionPayload, 'auction');
    const auctionState = _.get(auctionPayload, 'status');
    const validAuctionState = auctionState === 'pending' || auctionState === 'open';

    const renderCOQ = () => {
      return (
        <div className="collapsing-barge__barge" key={fuel.id}>
          <div className="container is-fullhd">
            <ViewCOQ fuel={fuel} supplierCOQ={supplierCOQ} allowedToDelete={validAuctionState} />
            {renderCOQForm()}
          </div>
        </div>
      );
    };

    const renderCOQForm = () => {
      if ((window.isAdmin && !window.isImpersonating) || validAuctionState) {
        return renderSubmitButton();
      } else { return ""; }
    }

    const renderSubmitButton = () => {
      if (this.state.uploading) {
        return (<button disabled={true} className="button is-primary full-width has-margin-bottom-md">Processing...</button>)
      } else {
        return (
          <label htmlFor={`coq-${fuel.id}`} className="button is-primary full-width has-margin-bottom-md">
            <input onChange={this.submitForm.bind(this)} name="coq" type="file" id={`coq-${fuel.id}`} hidden={true} />
            Upload COQ
          </label>
        )
      }
    }

    return (
      <div>
        { renderCOQ() }
      </div>
    );
  }
}

export default COQSubmission;
