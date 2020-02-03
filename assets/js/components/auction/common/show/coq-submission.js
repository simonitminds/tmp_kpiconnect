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
    ev.preventDefault();
    this.setState({ uploading: true });
    const form = ev.target;
    const data = new FormData(form);
    const coq = data.get("coq");
    const { addCOQ, auctionPayload, fuel, supplierId } = this.props;
    const { auction } = auctionPayload;
    addCOQ(auction.id, supplierId, fuel.id, coq);
    document.querySelector(`#coq-${fuel.id}`).value = null;
  }

  render() {
    const { auctionPayload, deleteCOQ, fuel, supplierCOQ } = this.props;
    const auction = _.get(auctionPayload, 'auction');
    const auctionState = _.get(auctionPayload, 'status');
    const validAuctionState = auctionState === 'pending' || auctionState === 'open';

    const renderCOQ = () => {
      return (
        <div className={`qa-coq-${fuel.id}`} key={fuel.id}>
          <ViewCOQ fuel={fuel} supplierCOQ={supplierCOQ} allowedToDelete={validAuctionState} />
          {renderCOQForm()}
        </div>
      );
    };

    const renderCOQForm = () => {
      if ((window.isAdmin && !window.isImpersonating) || validAuctionState) {
        return (
          <form onSubmit={this.submitForm.bind(this)}>
            <input name="coq" type="file" id={`coq-${fuel.id}`} />
            {renderSubmitButton()}
          </form>
        )
      }
    }

    const renderSubmitButton = () => {
      if (this.state.uploading) {
        return (<button disabled={true} className="button is-primary has-margin-top-sm">Processing...</button>)
      } else {
        return (<button type="submit" className="button is-primary has-margin-top-sm">Upload COQ</button>)
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
