import React from 'react';
import _ from 'lodash';

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
    const fuelId = data.get("fuelId");
    const coq = data.get("coq");
    const { addCOQ, auctionPayload, supplierId } = this.props;
    const { auction } = auctionPayload;
    addCOQ(auction.id, supplierId, fuelId, coq);
    document.querySelector(`#coq-${fuelId}`).value = null;
  }

  render() {
    const { auctionPayload, deleteCOQ, supplierId } = this.props;
    const auction = auctionPayload.auction
    const supplierCOQs = auction.auction_supplier_coqs;
    const fuels = auction.fuels;
    const auctionState = auctionPayload.status;
    const renderCOQUploadForm = (fuel) => {
      return (
        <div className={`qa-coq-${fuel.id}`} key={fuel.id}>
          <form onSubmit={this.submitForm.bind(this)}>
            {fuel.name}
            {renderCOQLink(auction.id, fuel.id, supplierId, supplierCOQs)}
            <input name="coq" type="file" id={`coq-${fuel.id}`} />
            <input name="fuelId" hidden={true} defaultValue={fuel.id} ref={(ref) => { this.fuelId = ref; }} />
            {renderSubmitButton()}
          </form>
        </div>
      );
    };

    const renderCOQLink = (auctionId, fuelId, supplierId, supplierCOQs) => {
      const supplierCOQ = _.find(supplierCOQs, { 'fuel_id': fuelId, 'supplier_id': parseInt(supplierId) });

      if (supplierCOQ) {
        return (
          <div>
            <a href={`/supplier_coq/${supplierCOQ.id}`} target="_blank">View COQ</a>
            <a className="button is-danger has-margin-top-sm" onClick={(e) => deleteCOQ(supplierCOQ.id)}>Delete</a>
          </div>
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
      <div className="box has-margin-bottom-md has-padding-bottom-none">
        <div className="box__subsection has-padding-bottom-none">
          <h3 className="box__header">COQs</h3>
          <div className="qa-coqs">
            {fuels.map(renderCOQUploadForm)}
          </div>
        </div>
      </div>
    );
  }
}

export default COQSubmission;
