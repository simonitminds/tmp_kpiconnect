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
    const { addCOQ, auctionPayload, fuel, supplierId, delivered } = this.props;
    const { auction } = auctionPayload;
    addCOQ(auction.id, supplierId, fuel.id, coq, delivered);
  }

  render() {
    const { auctionPayload, deleteCOQ, fuel, supplierId, supplierCOQ, delivered } = this.props;
    const auction = _.get(auctionPayload, 'auction');
    const auctionState = _.get(auctionPayload, 'status');
    const validAuctionState = auctionState === 'pending' || auctionState === 'open';

    const renderCOQ = () => {
      return (
        <div className="collapsing-barge__barge">
          <div className="container is-fullhd">
            <ViewCOQ fuel={fuel} supplierCOQ={supplierCOQ} deleteCOQ={deleteCOQ} allowedToDelete={(validAuctionState || delivered)} />
            {renderCOQForm()}
          </div>
        </div>
      );
    };

    const renderCOQForm = () => {
      if ((window.isAdmin && !window.isImpersonating) || (validAuctionState || delivered)) {
        return renderSubmitButton();
      } else { return ""; }
    }

    const renderSubmitButton = () => {
      if (this.state.uploading) {
        return (<button disabled={true} className="button is-primary full-width has-margin-bottom-md">Processing...</button>)
      } else {
        return (
          <label htmlFor={`coq-${supplierId}-${fuel.id}`} className="button is-primary full-width has-margin-bottom-md">
            <input onChange={this.submitForm.bind(this)} name="coq" type="file" id={`coq-${supplierId}-${fuel.id}`} hidden={true} />
            Upload COQ
          </label>
        )
      }
    }

    return renderCOQ()
  }
}

export default COQSubmission;
